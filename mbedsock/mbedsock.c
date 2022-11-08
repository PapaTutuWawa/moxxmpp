#include "mbedtls/ssl.h"
#include "mbedtls/entropy.h"
#include "mbedtls/net_sockets.h"
#include "mbedtls/ctr_drbg.h"
#include "mbedsock.h"

#include <stdbool.h>
#include <stdio.h>
#include <string.h>

struct mbedsock_ctx *mbedsock_ctx_new_ex(const char *capath) {
  struct mbedsock_ctx *ctx = malloc(sizeof(struct mbedsock_ctx));
  mbedsock_ctx_new(ctx, capath);

  return ctx;
}

struct mbedsock *mbedsock_new_ex(struct mbedsock_ctx *ctx) {
  struct mbedsock *sock = malloc(sizeof(struct mbedsock));
  mbedsock_new(ctx, sock);

  return sock;
}

int mbedsock_ctx_new(struct mbedsock_ctx *ctx, const char *capath) {
  int ret = 1;

  mbedtls_x509_crt_init(&ctx->chain);
  mbedtls_ctr_drbg_init(&ctx->ctr_drbg);
  mbedtls_entropy_init(&ctx->entropy);
  if ((ret = mbedtls_ctr_drbg_seed(&ctx->ctr_drbg, mbedtls_entropy_func, &ctx->entropy,
				   (unsigned char *) SSL_PERS,
				   SSL_PERS_LEN)) != 0)
    return ret;

  if((ret = mbedtls_x509_crt_parse_path(&ctx->chain, capath)) < 0 )
    return ret;
  
  return 0;
}

int mbedsock_new(struct mbedsock_ctx *ctx, struct mbedsock *sock) {
  int ret = 1;
  mbedtls_net_init(&sock->server_fd);
  mbedtls_ssl_init(&sock->ssl);
  mbedtls_ssl_config_init(&sock->conf);

  mbedtls_ssl_conf_authmode(&sock->conf, MBEDTLS_SSL_VERIFY_REQUIRED);
  mbedtls_ssl_conf_ca_chain(&sock->conf, &ctx->chain, NULL);
  mbedtls_ssl_conf_rng(&sock->conf, mbedtls_ctr_drbg_random, &ctx->ctr_drbg);

  if ((ret = mbedtls_ssl_setup(&sock->ssl, &sock->conf)) != 0)
    return ret;

  mbedtls_ssl_set_bio(&sock->ssl, &sock->server_fd, mbedtls_net_send, mbedtls_net_recv, NULL);

  if ((ret = mbedtls_ssl_config_defaults(&sock->conf, MBEDTLS_SSL_IS_CLIENT, MBEDTLS_SSL_TRANSPORT_STREAM, MBEDTLS_SSL_PRESET_DEFAULT)) != 0)
    return ret;

  sock->secure = false;
  sock->read_cb = NULL;
  
  return 0;
}

void mbedsock_free(struct mbedsock *sock) {
  mbedtls_net_free(&sock->server_fd);
  mbedtls_ssl_free(&sock->ssl);
  mbedtls_ssl_config_free(&sock->conf);
}

void mbedsock_ctx_free(struct mbedsock_ctx *ctx) {
  mbedtls_x509_crt_free(&ctx->chain);
  mbedtls_ctr_drbg_free(&ctx->ctr_drbg);
  mbedtls_entropy_free(&ctx->entropy);
}

void mbedsock_free_ex(struct mbedsock *sock) {
  mbedsock_free(sock);
  free(sock);
}

void mbedsock_ctx_free_ex(struct mbedsock_ctx *ctx) {
  mbedsock_ctx_free(ctx);
  free(ctx);
}

int mbedsock_do_handshake(struct mbedsock *sock, const char *alpn, const char *sni) {
  int ret = 1;

  // Set ALPN, if desired
  if (alpn != NULL) {
    const char *alpn_list[2];
    alpn_list[0] = alpn;
    alpn_list[1] = NULL;

    if ((ret = mbedtls_ssl_conf_alpn_protocols(&sock->conf, alpn_list)) != 0) {
      return ret;
    }
  }

  // Set SNI, if desired
  if (sni != NULL) {
    if ((ret = mbedtls_ssl_set_hostname(&sock->ssl, sni)) != 0) {
      return ret;
    }
  }
  
  while ((ret = mbedtls_ssl_handshake(&sock->ssl)) != 0) {
    if( ret != MBEDTLS_ERR_SSL_WANT_READ && ret != MBEDTLS_ERR_SSL_WANT_WRITE )
      return ret;
  }

  // Verify the certificates
  if ((ret = mbedtls_ssl_get_verify_result(&sock->ssl)) != 0) {
    return ret;
  }

  sock->secure = true;
  return 0;
}

int mbedsock_connect_secure(struct mbedsock *sock, const char *host, const char *port, const char *alpn, const char *sni) {
  int ret = 1;

  if ((ret = mbedtls_net_connect(&sock->server_fd, host, port, MBEDTLS_NET_PROTO_TCP)) != 0)
    return ret;

  if ((ret = mbedsock_do_handshake(sock, alpn, sni)))
    return ret;
  
  return 0;
}

int mbedsock_connect(struct mbedsock *sock, const char *host, const char *port) {
  return mbedtls_net_connect(&sock->server_fd, host, port, MBEDTLS_NET_PROTO_TCP);
}

int mbedsock_write(struct mbedsock *sock, const unsigned char *data, int len) {
  int ret = 1;

  if (sock->secure) {
    while ((ret = mbedtls_ssl_write(&sock->ssl, data, len)) <= 0) {
	if(ret != MBEDTLS_ERR_SSL_WANT_READ && ret != MBEDTLS_ERR_SSL_WANT_WRITE)
	return -1;
    }
  } else {
    if ((ret = mbedtls_net_send(&sock->server_fd, data, len)) <= 0)
      return -1;
  }

  return ret;
}

int mbedsock_read(struct mbedsock *sock, unsigned char *buf, int len) {
  int ret = 1;

  memset(buf, 0, len);
  if (sock->secure) {
    do {
      ret = mbedtls_ssl_read(&sock->ssl, buf, len);

      if (ret == MBEDTLS_ERR_SSL_WANT_READ || ret == MBEDTLS_ERR_SSL_WANT_WRITE)
          continue;

      // TODO: Notify
      if (ret == MBEDTLS_ERR_SSL_PEER_CLOSE_NOTIFY)
          break;

      if (ret < 0)
	return -1;

      return ret;
    } while (true);
  } else {
    ret = mbedtls_net_recv(&sock->server_fd, buf, len);

    if (ret < 0)
      return -1;

    return ret;
  }

  return 0;
}

bool mbedsock_is_secure(struct mbedsock *sock) {
  return sock->secure;
}

void mbedsock_set_read_cb(struct mbedsock *sock, void (*read_cb)(int)) {
  sock->read_cb = read_cb;
}

struct mbedsock_thread_data {
  struct mbedsock *sock;
  unsigned char *buf;
  int len;
};

void _mbedsock_read_loop(void *args) {
  struct mbedsock_thread_data *data = (struct mbedsock_thread_data *) args;
  struct mbedsock *sock = data->sock;
  unsigned char *buf = data->buf;
  int len = data->len;
  int result = 1;

  printf("args2: %p\n", args);
  printf("bufptr2: %p\n", buf);
  printf("len: %d\n", len);

  free(data);

  while (true) {
    result = mbedsock_read(sock, buf, len);
    sock->read_cb(result);

    if (result <= 0)
      break;
  }

  pthread_exit(NULL);
}

int mbedsock_run_read_loop(struct mbedsock *sock, unsigned char *buf, int len) {
  if (sock->read_cb == NULL)
    return -1;

  sock->read_cb(42);
  
  struct mbedsock_thread_data *data = malloc(sizeof(struct mbedsock_thread_data));
  data->sock = sock;
  data->buf = buf;
  data->len = len;

  printf("bufptr: %p\n", buf);
  printf("args: %p\n", &data);
  pthread_create(&sock->thread, NULL, &_mbedsock_read_loop, (void *) data);
  return 0;
}
