#ifndef __MBEDSOCK_H__
#define __MBEDSOCK_H__

#include "mbedtls/ssl.h"
#include "mbedtls/entropy.h"
#include "mbedtls/net_sockets.h"
#include "mbedtls/ctr_drbg.h"

#include <stdbool.h>
#include <pthread.h>

#define SSL_PERS "moxxmpp_socket"
#define SSL_PERS_LEN sizeof(SSL_PERS)/sizeof(char)

/*
 * The context for the sockets. This must be created once and is shared between all
 * sockets.
 */
struct mbedsock_ctx {
  mbedtls_entropy_context entropy;
  mbedtls_ctr_drbg_context ctr_drbg;
  mbedtls_x509_crt chain;
};

/*
 * The data for the socket.
 */
struct mbedsock {
  mbedtls_ssl_context ssl;
  mbedtls_ssl_config conf;
  mbedtls_net_context server_fd;

  // The thread the socket runs in
  pthread_t thread;

  // The callback function when the read loop is running
  void (*read_cb)(int);
  
  // Indicates whether the socket is secured using TLS (true) or not (false).
  bool secure;
};

/*
 * Create a new mbedsock_ctx context and write it to @ctx. @capath is the path
 * to the directory containing the system's .crt root CA files.
 *
 * Returns true if everything went well; something non-zero on errors.
 */
int mbedsock_ctx_new(struct mbedsock_ctx *ctx, const char *capath);
struct mbedsock_ctx *mbedsock_ctx_new_ex(const char *capath);

/*
 * Create a new socket using the context @ctx and writes it to @sock. Returns zero
 * on success; something non-zero on error.
 */
int mbedsock_new(struct mbedsock_ctx *ctx, struct mbedsock *sock);
struct mbedsock *mbedsock_new_ex(struct mbedsock_ctx *ctx);

/*
 * Free the resources used by @sock.
 */
void mbedsock_free(struct mbedsock *sock);
void mbedsock_free_ex(struct mbedsock *sock);

/*
 * Free the resources used by @ctx.
 */
void mbedsock_ctx_free(struct mbedsock_ctx *ctx);
void mbedsock_ctx_free_ex(struct mbedsock_ctx *ctx);

/*
 * Performs the TLS handshake and upgrades the connection @sock to a secured one.
 * If @alpn is not NULL, then its value will be used for TLS ALPN. If @sni is not NULL,
 * then its value will be used for Server Name Indication.
 *
 * Returns 0 on success; something non-zero on failure.
 */
int mbedsock_do_handshake(struct mbedsock *sock, const char *alpn, const char *sni);

/*
 * Use socket @sock to to connect to @host:@port and immediately call
 * mbedsock_do_handshake. @alpn and @sni are used for mbedsock_do_handshake.
 *
 * Returns 0 on success; something non-zero on failure.
 */
int mbedsock_connect_secure(struct mbedsock *sock, const char *host, const char *port, const char *alpn, const char *sni);

/*
 * Use socket @sock to to connect to @host:@port. The socket is not secured on success.
 *
 * Returns 0 on success; something non-zero on failure.
 */
int mbedsock_connect(struct mbedsock *sock, const char *host, const char *port);

/*
 * Write @data - @len being the amount of bytes in data to read - to @sock. The function
 * uses @sock's secure attribute to decide whether to use TLS or not.
 *
 * Returns the amount of bytes written on success. The documentation for
 * mbedtls_ssl_write and mbedtls_net_send apply for the return value. Returns -1
 * if an error occurred.
 */
int mbedsock_write(struct mbedsock *sock, const unsigned char *data, int len);

/*
 * Read data from @sock into @buf. @len is the size of the buffer.
 *
 * Returns the amount of bytes read on success. The documentation for
 * mbedtls_ssl_read and mbedtls_net_recv apply for the return value. Returns -1
 * if an error occurred.
 */
int mbedsock_read(struct mbedsock *sock, unsigned char *buf, int len);

bool mbedsock_is_secure(struct mbedsock *sock);

void mbedsock_set_read_cb(struct mbedsock *sock, void (*read_cb)(int));

int mbedsock_run_read_loop(struct mbedsock *sock, unsigned char *buf, int len);

#endif // __MBEDSOCK_H__
