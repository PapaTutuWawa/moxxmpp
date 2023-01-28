{fetchzip, runCommand} : rec {
  _fe_analyzer_shared = fetchzip {
    sha256 = "1hyd5pmjcfyvfwhsc0wq6k0229abmqq5zn95g31hh42bklb2gci5";
    url = "https://pub.dartlang.org/packages/_fe_analyzer_shared/versions/50.0.0.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  analyzer = fetchzip {
    sha256 = "0niy5b3w39aywpjpw5a84pxdilhh3zzv1c22x8ywml756pybmj4r";
    url = "https://pub.dartlang.org/packages/analyzer/versions/5.2.0.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  args = fetchzip {
    sha256 = "0c78zkzg2d2kzw1qrpiyrj1qvm4pr0yhnzapbqk347m780ha408g";
    url = "https://pub.dartlang.org/packages/args/versions/2.3.1.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  async = fetchzip {
    sha256 = "00hhylamsjcqmcbxlsrfimri63gb384l31r9mqvacn6c6bvk4yfx";
    url = "https://pub.dartlang.org/packages/async/versions/2.10.0.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  boolean_selector = fetchzip {
    sha256 = "0hxq8072hb89q9s91xlz9fvrjxfy7hw6jkdwkph5dp77df841kmj";
    url = "https://pub.dartlang.org/packages/boolean_selector/versions/2.1.1.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  build = fetchzip {
    sha256 = "1x6nkii6kqy6y7ck0151yfhc9lp2nvbhznnhdi2mxr8afk6jxigd";
    url = "https://pub.dartlang.org/packages/build/versions/2.3.1.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  build_config = fetchzip {
    sha256 = "092rrbhbdy9fk50jqb1fwj1sfk415fi43irvsd0hk5w90gn8vazj";
    url = "https://pub.dartlang.org/packages/build_config/versions/1.1.1.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  build_daemon = fetchzip {
    sha256 = "0b6hnwjc3gi5g7cnpy8xyiqigcrs0xp51c7y7v1pqn9v75g25w6j";
    url = "https://pub.dartlang.org/packages/build_daemon/versions/3.1.0.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  build_resolvers = fetchzip {
    sha256 = "0fnrisgq6rnvbqsf8v43hb11kr1qq6azrxbsvx3wwimd37nxx8m5";
    url = "https://pub.dartlang.org/packages/build_resolvers/versions/2.1.0.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  build_runner = fetchzip {
    sha256 = "0246bxl9rxgil55fhfzi7csd9a56blj9s1j1z79717hiyzsr60x6";
    url = "https://pub.dartlang.org/packages/build_runner/versions/2.3.2.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  build_runner_core = fetchzip {
    sha256 = "0bpil0fw0dag3vbnin9p945ymi7xjgkiy7jrq9j52plljf7cnf5z";
    url = "https://pub.dartlang.org/packages/build_runner_core/versions/7.2.7.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  built_collection = fetchzip {
    sha256 = "0bqjahxr42q84w91nhv3n4cr580l3s3ffx3vgzyyypgqnrck0hv3";
    url = "https://pub.dartlang.org/packages/built_collection/versions/5.1.1.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  built_value = fetchzip {
    sha256 = "0sslr4258snvcj8qhbdk6wapka174als0viyxddwqlnhs7dlci8i";
    url = "https://pub.dartlang.org/packages/built_value/versions/8.4.2.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  checked_yaml = fetchzip {
    sha256 = "1gf7ankc5jb7mk17br87ajv05pfg6vb8nf35ay6c35w8jp70ra7k";
    url = "https://pub.dartlang.org/packages/checked_yaml/versions/2.0.1.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  code_builder = fetchzip {
    sha256 = "1vl9dl23yd0zjw52ndrazijs6dw83fg1rvyb2gfdpd6n1lj9nbhg";
    url = "https://pub.dartlang.org/packages/code_builder/versions/4.3.0.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  collection = fetchzip {
    sha256 = "1iyl3v3j7mj3sxjf63b1kc182fwrwd04mjp5x2i61hic8ihfw545";
    url = "https://pub.dartlang.org/packages/collection/versions/1.17.0.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  convert = fetchzip {
    sha256 = "0adsigjk3l1c31i6k91p28dqyjlgwiqrs4lky5djrm2scf8k6cri";
    url = "https://pub.dartlang.org/packages/convert/versions/3.1.1.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  coverage = fetchzip {
    sha256 = "0akbg1yp2h4vprc8r9xvrpgvp5d26h7m80h5sbzgr5dlis1bcw0d";
    url = "https://pub.dartlang.org/packages/coverage/versions/1.6.1.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  crypto = fetchzip {
    sha256 = "1kjfb8fvdxazmv9ps2iqdhb8kcr31115h0nwn6v4xmr71k8jb8ds";
    url = "https://pub.dartlang.org/packages/crypto/versions/3.0.2.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  cryptography = fetchzip {
    sha256 = "0jqph45d9lbhdakprnb84c3qhk4aq05hhb1pmn8w23yhl41ypijs";
    url = "https://pub.dartlang.org/packages/cryptography/versions/2.0.5.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  dart_style = fetchzip {
    sha256 = "01wg15kalbjlh4i3xbawc9zk8yrk28qhak7xp7mlwn2syhdckn7v";
    url = "https://pub.dartlang.org/packages/dart_style/versions/2.2.4.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  file = fetchzip {
    sha256 = "0ajcfblf8d4dicp1sgzkbrhd0b0v0d8wl70jsnf5drjck3p3ppk7";
    url = "https://pub.dartlang.org/packages/file/versions/6.1.4.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  fixnum = fetchzip {
    sha256 = "1m8cdfqp9d6w1cik3fwz9bai1wf9j11rjv2z0zlv7ich87q9kkjk";
    url = "https://pub.dartlang.org/packages/fixnum/versions/1.0.1.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  freezed = fetchzip {
    sha256 = "1i9s4djf4vlz56zqn8brcck3n7sk07qay23wmaan991cqydd10iq";
    url = "https://pub.dartlang.org/packages/freezed/versions/2.1.1.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  freezed_annotation = fetchzip {
    sha256 = "0ym120dh1lpfnb68gxh1finm8p9l445q5x10aw8269y469b9k9z3";
    url = "https://pub.dartlang.org/packages/freezed_annotation/versions/2.1.0.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  frontend_server_client = fetchzip {
    sha256 = "0nv4avkv2if9hdcfzckz36f3mclv7vxchivrg8j3miaqhnjvv4bj";
    url = "https://pub.dartlang.org/packages/frontend_server_client/versions/3.1.0.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  glob = fetchzip {
    sha256 = "0a6gbwsbz6rkg35dkff0zv88rvcflqdmda90hdfpn7jp1z1w9rhs";
    url = "https://pub.dartlang.org/packages/glob/versions/2.1.0.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  graphs = fetchzip {
    sha256 = "0cr6dgs1a7ln2ir5gd0kiwpn787lk4dwhqfjv8876hkkr1rv80m9";
    url = "https://pub.dartlang.org/packages/graphs/versions/2.2.0.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  hex = fetchzip {
    sha256 = "19w3f90mdiy06a6kf8hlwc4jn4cxixkj106kc3g3bis27ar7smkh";
    url = "https://pub.dartlang.org/packages/hex/versions/0.2.0.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  http_multi_server = fetchzip {
    sha256 = "1zdcm04z85jahb2hs7qs85rh974kw49hffhy9cn1gfda3077dvql";
    url = "https://pub.dartlang.org/packages/http_multi_server/versions/3.2.1.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  http_parser = fetchzip {
    sha256 = "027c4sjkhkkx3sk1aqs6s4djb87syi9h521qpm1bf21bq3gga5jd";
    url = "https://pub.dartlang.org/packages/http_parser/versions/4.0.2.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  io = fetchzip {
    sha256 = "1bp5l8hkrp6fjj7zw9af51hxyp52sjspc5558lq0lmi453l0czni";
    url = "https://pub.dartlang.org/packages/io/versions/1.0.3.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  js = fetchzip {
    sha256 = "13fbxgyg1v6bmzvxamg6494vk3923fn3mgxj6f4y476aqwk99n50";
    url = "https://pub.dartlang.org/packages/js/versions/0.6.5.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  json_annotation = fetchzip {
    sha256 = "1p9nvn33psx2zbalhyqjw8gr4agd76jj5jq0fdz0i584c7l77bby";
    url = "https://pub.dartlang.org/packages/json_annotation/versions/4.7.0.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  json_serializable = fetchzip {
    sha256 = "04d7laaxrbiybcgbv3y223hy8d6n9f84h5lv9sv79zd9ffzkb2hg";
    url = "https://pub.dartlang.org/packages/json_serializable/versions/6.5.4.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  logging = fetchzip {
    sha256 = "0hl1mjh662c44ci7z60x92i0jsyqg1zm6k6fc89n9pdcxsqdpwfs";
    url = "https://pub.dartlang.org/packages/logging/versions/1.0.2.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  matcher = fetchzip {
    sha256 = "0pjgc38clnjbv124n8bh724db1wcc4kk125j7dxl0icz7clvm0p0";
    url = "https://pub.dartlang.org/packages/matcher/versions/0.12.13.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  meta = fetchzip {
    sha256 = "01kqdd25nln5a219pr94s66p27m0kpqz0wpmwnm24kdy3ngif1v5";
    url = "https://pub.dartlang.org/packages/meta/versions/1.8.0.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  mime = fetchzip {
    sha256 = "1dr3qikzvp10q1saka7azki5gk2kkf2v7k9wfqjsyxmza2zlv896";
    url = "https://pub.dartlang.org/packages/mime/versions/1.0.2.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  moxlib = fetchzip {
    sha256 = "1j52xglpwy8c7dbylc3f6vrh0p52xhhwqs4h0qcqk8c1rvjn5czq";
    url = "https://git.polynom.me/api/packages/moxxy/pub/api/packages/moxlib/files/0.1.5.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  node_preamble = fetchzip {
    sha256 = "0i0gfc2yqa09182vc01lj47qpq98kfm9m8h4n8c5fby0mjd0lvyx";
    url = "https://pub.dartlang.org/packages/node_preamble/versions/2.0.1.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  omemo_dart = fetchzip {
    sha256 = "09x3jqa11hjdjp31nxnz91j6jssbc2f8a1lh44fmkc0d79hs8bbi";
    url = "https://git.polynom.me/api/packages/PapaTutuWawa/pub/api/packages/omemo_dart/files/0.4.3.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  package_config = fetchzip {
    sha256 = "1d4l0i4cby344zj45f5shrg2pkw1i1jn03kx0qqh0l7gh1ha7bpc";
    url = "https://pub.dartlang.org/packages/package_config/versions/2.1.0.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  path = fetchzip {
    sha256 = "16ggdh29ciy7h8sdshhwmxn6dd12sfbykf2j82c56iwhhlljq181";
    url = "https://pub.dartlang.org/packages/path/versions/1.8.2.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  pedantic = fetchzip {
    sha256 = "10ch0h3hi6cfwiz2ihfkh6m36m75c0m7fd0wwqaqggffsj2dn8ad";
    url = "https://pub.dartlang.org/packages/pedantic/versions/1.11.1.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  petitparser = fetchzip {
    sha256 = "1pqqqqiy9ald24qsi24q9qrr0zphgpsrnrv9rlx4vwr6xak7d8c0";
    url = "https://pub.dartlang.org/packages/petitparser/versions/5.1.0.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  pinenacl = fetchzip {
    sha256 = "0didjgva658z90hbcmhd0y8w1b8v86dp6gabfhylnw1aixl47cxg";
    url = "https://pub.dartlang.org/packages/pinenacl/versions/0.5.1.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  pool = fetchzip {
    sha256 = "0wmzs46hjszv3ayhr1p5l7xza7q9rkg2q9z4swmhdqmhlz3c50x4";
    url = "https://pub.dartlang.org/packages/pool/versions/1.5.1.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  pub_semver = fetchzip {
    sha256 = "1vsj5c1f2dza4l5zmjix4zh65lp8gsg6pw01h57pijx2id0g4bwi";
    url = "https://pub.dartlang.org/packages/pub_semver/versions/2.1.2.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  pubspec_parse = fetchzip {
    sha256 = "19dmr9k4wsqjnhlzp1lbrw8dv7a1gnwmr8l5j9zlw407rmfg20d1";
    url = "https://pub.dartlang.org/packages/pubspec_parse/versions/1.2.1.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  random_string = fetchzip {
    sha256 = "11cjiv75sgldvk3x7w6j77lgi08r6737wm94m3ylabylsr6zdyff";
    url = "https://pub.dartlang.org/packages/random_string/versions/2.3.1.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  saslprep = fetchzip {
    sha256 = "04lss0xvm6p801p8306jdxg7k0b28kr6n65dz2f57dkca237kcw7";
    url = "https://pub.dartlang.org/packages/saslprep/versions/1.0.2.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  shelf = fetchzip {
    sha256 = "0x2xl7glrnq0hdxpy2i94a4wxbdrd6dm46hvhzgjn8alsm8z0wz1";
    url = "https://pub.dartlang.org/packages/shelf/versions/1.4.0.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  shelf_packages_handler = fetchzip {
    sha256 = "199rbdbifj46lg3iynznnsbs8zr4dfcw0s7wan8v73nvpqvli82q";
    url = "https://pub.dartlang.org/packages/shelf_packages_handler/versions/3.0.1.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  shelf_static = fetchzip {
    sha256 = "1kqbaslz7bna9lldda3ibrjg0gczbzlwgm9cic8shg0bnl0v3s34";
    url = "https://pub.dartlang.org/packages/shelf_static/versions/1.1.1.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  shelf_web_socket = fetchzip {
    sha256 = "0rr87nx2wdf9alippxiidqlgi82fbprnsarr1jswg9qin0yy4jpn";
    url = "https://pub.dartlang.org/packages/shelf_web_socket/versions/1.0.3.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  source_gen = fetchzip {
    sha256 = "1kxgx782lzpjhv736h0pz3lnxpcgiy05h0ysy0q77gix8q09i1hz";
    url = "https://pub.dartlang.org/packages/source_gen/versions/1.2.6.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  source_helper = fetchzip {
    sha256 = "044kzmzlfpx93s4raz5avijahizmvai0zvl0lbm4wi93ynhdp1pd";
    url = "https://pub.dartlang.org/packages/source_helper/versions/1.3.3.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  source_map_stack_trace = fetchzip {
    sha256 = "0b5d4c5n5qd3j8n10gp1khhr508wfl3819bhk6xnl34qxz8n032k";
    url = "https://pub.dartlang.org/packages/source_map_stack_trace/versions/2.1.1.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  source_maps = fetchzip {
    sha256 = "18ixrlz3l2alk3hp0884qj0mcgzhxmjpg6nq0n1200pfy62pc4z6";
    url = "https://pub.dartlang.org/packages/source_maps/versions/0.10.11.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  source_span = fetchzip {
    sha256 = "1lq4sy7lw15qsv9cijf6l48p16qr19r7njzwr4pxn8vv1kh6rb86";
    url = "https://pub.dartlang.org/packages/source_span/versions/1.9.1.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  stack_trace = fetchzip {
    sha256 = "0bggqvvpkrfvqz24bnir4959k0c45azc3zivk4lyv3mvba6092na";
    url = "https://pub.dartlang.org/packages/stack_trace/versions/1.11.0.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  stream_channel = fetchzip {
    sha256 = "054by84c60yxphr3qgg6f82gg6d22a54aqjp265anlm8dwz1ji32";
    url = "https://pub.dartlang.org/packages/stream_channel/versions/2.1.1.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  stream_transform = fetchzip {
    sha256 = "0jq6767v9ds17i2nd6mdd9i0f7nvsgg3dz74d0v54x66axjgr0gp";
    url = "https://pub.dartlang.org/packages/stream_transform/versions/2.1.0.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  string_scanner = fetchzip {
    sha256 = "0p1r0v2923avwfg03rk0pmc6f21m0zxpcx6i57xygd25k6hdfi00";
    url = "https://pub.dartlang.org/packages/string_scanner/versions/1.2.0.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  synchronized = fetchzip {
    sha256 = "1j6108cq1hbcqpwhk9sah8q3gcidd7222bzhha2nk9syxhzqy82i";
    url = "https://pub.dartlang.org/packages/synchronized/versions/3.0.0%2B2.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  term_glyph = fetchzip {
    sha256 = "1x8nspxaccls0sxjamp703yp55yxdvhj6wg21lzwd296i9rwlxh9";
    url = "https://pub.dartlang.org/packages/term_glyph/versions/1.2.1.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  test = fetchzip {
    sha256 = "08kimbjvkdw3bkj7za36p3yqdr8dnlb5v30c250kvdncb7k09h4x";
    url = "https://pub.dartlang.org/packages/test/versions/1.22.0.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  test_api = fetchzip {
    sha256 = "0mfyjpqkkmaqdh7xygrydx12591wq9ll816f61n80dc6rmkdx7px";
    url = "https://pub.dartlang.org/packages/test_api/versions/0.4.16.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  test_core = fetchzip {
    sha256 = "1r8dnvkxxvh55z1c8lrsja1m0dkf5i4lgwwqixcx0mqvxx5w3005";
    url = "https://pub.dartlang.org/packages/test_core/versions/0.4.20.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  timing = fetchzip {
    sha256 = "0a02znvy0fbzr0n4ai67pp8in7w6m768aynkk1kp5lnmgy17ppsg";
    url = "https://pub.dartlang.org/packages/timing/versions/1.0.0.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  typed_data = fetchzip {
    sha256 = "1x402bvyzdmdvmyqhyfamjxf54p9j8sa8ns2n5dwsdhnfqbw859g";
    url = "https://pub.dartlang.org/packages/typed_data/versions/1.3.1.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  unorm_dart = fetchzip {
    sha256 = "05kyk2764yz14pzgx00i7h5b1lzh8kjqnxspfzyf8z920bcgbz0v";
    url = "https://pub.dartlang.org/packages/unorm_dart/versions/0.2.0.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  uuid = fetchzip {
    sha256 = "12lsynr07lw9848jknmzxvzn3ia12xdj07iiva0vg0qjvpq7ladg";
    url = "https://pub.dartlang.org/packages/uuid/versions/3.0.5.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  very_good_analysis = fetchzip {
    sha256 = "1p2dh8aahbqyyqfzbsxswafgxnmxgisjq2xfp008skyh7imk6sz4";
    url = "https://pub.dartlang.org/packages/very_good_analysis/versions/3.1.0.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  vm_service = fetchzip {
    sha256 = "05xaxaxzyfls6jklw1hzws2jmina1cjk10gbl7a63djh1ghnzjb5";
    url = "https://pub.dartlang.org/packages/vm_service/versions/9.4.0.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  watcher = fetchzip {
    sha256 = "1sk7gvwa7s0h4l652qrgbh7l8wyqc6nr6lki8m4rj55720p0fnyg";
    url = "https://pub.dartlang.org/packages/watcher/versions/1.0.2.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  web_socket_channel = fetchzip {
    sha256 = "147amn05v1f1a1grxjr7yzgshrczjwijwiywggsv6dgic8kxyj5a";
    url = "https://pub.dartlang.org/packages/web_socket_channel/versions/2.2.0.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  webkit_inspection_protocol = fetchzip {
    sha256 = "0z400dzw7gf68a3wm95xi2mf461iigkyq6x69xgi7qs3fvpmn3hx";
    url = "https://pub.dartlang.org/packages/webkit_inspection_protocol/versions/1.2.0.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  xml = fetchzip {
    sha256 = "0jwknkfcnb5svg6r01xjsj0aiw06mlx54pgay1ymaaqm2mjhyz01";
    url = "https://pub.dartlang.org/packages/xml/versions/6.2.0.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  yaml = fetchzip {
    sha256 = "0mqqmzn3c9rr38b5xm312fz1vyp6vb36lm477r9hak77bxzpp0iw";
    url = "https://pub.dartlang.org/packages/yaml/versions/3.1.1.tar.gz";
    stripRoot = false;
    extension = "tar.gz";
  };

  pubCache = runCommand "moxxmpp-pub-cache" {} ''
    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${_fe_analyzer_shared} $out/hosted/pub.dartlang.org/_fe_analyzer_shared-50.0.0

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${analyzer} $out/hosted/pub.dartlang.org/analyzer-5.2.0

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${args} $out/hosted/pub.dartlang.org/args-2.3.1

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${async} $out/hosted/pub.dartlang.org/async-2.10.0

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${boolean_selector} $out/hosted/pub.dartlang.org/boolean_selector-2.1.1

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${build} $out/hosted/pub.dartlang.org/build-2.3.1

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${build_config} $out/hosted/pub.dartlang.org/build_config-1.1.1

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${build_daemon} $out/hosted/pub.dartlang.org/build_daemon-3.1.0

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${build_resolvers} $out/hosted/pub.dartlang.org/build_resolvers-2.1.0

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${build_runner} $out/hosted/pub.dartlang.org/build_runner-2.3.2

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${build_runner_core} $out/hosted/pub.dartlang.org/build_runner_core-7.2.7

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${built_collection} $out/hosted/pub.dartlang.org/built_collection-5.1.1

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${built_value} $out/hosted/pub.dartlang.org/built_value-8.4.2

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${checked_yaml} $out/hosted/pub.dartlang.org/checked_yaml-2.0.1

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${code_builder} $out/hosted/pub.dartlang.org/code_builder-4.3.0

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${collection} $out/hosted/pub.dartlang.org/collection-1.17.0

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${convert} $out/hosted/pub.dartlang.org/convert-3.1.1

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${coverage} $out/hosted/pub.dartlang.org/coverage-1.6.1

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${crypto} $out/hosted/pub.dartlang.org/crypto-3.0.2

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${cryptography} $out/hosted/pub.dartlang.org/cryptography-2.0.5

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${dart_style} $out/hosted/pub.dartlang.org/dart_style-2.2.4

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${file} $out/hosted/pub.dartlang.org/file-6.1.4

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${fixnum} $out/hosted/pub.dartlang.org/fixnum-1.0.1

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${freezed} $out/hosted/pub.dartlang.org/freezed-2.1.1

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${freezed_annotation} $out/hosted/pub.dartlang.org/freezed_annotation-2.1.0

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${frontend_server_client} $out/hosted/pub.dartlang.org/frontend_server_client-3.1.0

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${glob} $out/hosted/pub.dartlang.org/glob-2.1.0

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${graphs} $out/hosted/pub.dartlang.org/graphs-2.2.0

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${hex} $out/hosted/pub.dartlang.org/hex-0.2.0

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${http_multi_server} $out/hosted/pub.dartlang.org/http_multi_server-3.2.1

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${http_parser} $out/hosted/pub.dartlang.org/http_parser-4.0.2

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${io} $out/hosted/pub.dartlang.org/io-1.0.3

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${js} $out/hosted/pub.dartlang.org/js-0.6.5

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${json_annotation} $out/hosted/pub.dartlang.org/json_annotation-4.7.0

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${json_serializable} $out/hosted/pub.dartlang.org/json_serializable-6.5.4

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${logging} $out/hosted/pub.dartlang.org/logging-1.0.2

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${matcher} $out/hosted/pub.dartlang.org/matcher-0.12.13

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${meta} $out/hosted/pub.dartlang.org/meta-1.8.0

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${mime} $out/hosted/pub.dartlang.org/mime-1.0.2

    mkdir -p $out/hosted/git.polynom.me%47api%47packages%47Moxxy%47pub%47
    ln -s ${moxlib} $out/hosted/git.polynom.me%47api%47packages%47Moxxy%47pub%47/moxlib-0.1.5

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${node_preamble} $out/hosted/pub.dartlang.org/node_preamble-2.0.1

    mkdir -p $out/hosted/git.polynom.me%47api%47packages%47PapaTutuWawa%47pub%47
    ln -s ${omemo_dart} $out/hosted/git.polynom.me%47api%47packages%47PapaTutuWawa%47pub%47/omemo_dart-0.4.3

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${package_config} $out/hosted/pub.dartlang.org/package_config-2.1.0

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${path} $out/hosted/pub.dartlang.org/path-1.8.2

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${pedantic} $out/hosted/pub.dartlang.org/pedantic-1.11.1

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${petitparser} $out/hosted/pub.dartlang.org/petitparser-5.1.0

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${pinenacl} $out/hosted/pub.dartlang.org/pinenacl-0.5.1

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${pool} $out/hosted/pub.dartlang.org/pool-1.5.1

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${pub_semver} $out/hosted/pub.dartlang.org/pub_semver-2.1.2

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${pubspec_parse} $out/hosted/pub.dartlang.org/pubspec_parse-1.2.1

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${random_string} $out/hosted/pub.dartlang.org/random_string-2.3.1

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${saslprep} $out/hosted/pub.dartlang.org/saslprep-1.0.2

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${shelf} $out/hosted/pub.dartlang.org/shelf-1.4.0

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${shelf_packages_handler} $out/hosted/pub.dartlang.org/shelf_packages_handler-3.0.1

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${shelf_static} $out/hosted/pub.dartlang.org/shelf_static-1.1.1

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${shelf_web_socket} $out/hosted/pub.dartlang.org/shelf_web_socket-1.0.3

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${source_gen} $out/hosted/pub.dartlang.org/source_gen-1.2.6

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${source_helper} $out/hosted/pub.dartlang.org/source_helper-1.3.3

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${source_map_stack_trace} $out/hosted/pub.dartlang.org/source_map_stack_trace-2.1.1

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${source_maps} $out/hosted/pub.dartlang.org/source_maps-0.10.11

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${source_span} $out/hosted/pub.dartlang.org/source_span-1.9.1

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${stack_trace} $out/hosted/pub.dartlang.org/stack_trace-1.11.0

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${stream_channel} $out/hosted/pub.dartlang.org/stream_channel-2.1.1

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${stream_transform} $out/hosted/pub.dartlang.org/stream_transform-2.1.0

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${string_scanner} $out/hosted/pub.dartlang.org/string_scanner-1.2.0

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${synchronized} $out/hosted/pub.dartlang.org/synchronized-3.0.0+2

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${term_glyph} $out/hosted/pub.dartlang.org/term_glyph-1.2.1

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${test} $out/hosted/pub.dartlang.org/test-1.22.0

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${test_api} $out/hosted/pub.dartlang.org/test_api-0.4.16

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${test_core} $out/hosted/pub.dartlang.org/test_core-0.4.20

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${timing} $out/hosted/pub.dartlang.org/timing-1.0.0

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${typed_data} $out/hosted/pub.dartlang.org/typed_data-1.3.1

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${unorm_dart} $out/hosted/pub.dartlang.org/unorm_dart-0.2.0

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${uuid} $out/hosted/pub.dartlang.org/uuid-3.0.5

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${very_good_analysis} $out/hosted/pub.dartlang.org/very_good_analysis-3.1.0

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${vm_service} $out/hosted/pub.dartlang.org/vm_service-9.4.0

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${watcher} $out/hosted/pub.dartlang.org/watcher-1.0.2

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${web_socket_channel} $out/hosted/pub.dartlang.org/web_socket_channel-2.2.0

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${webkit_inspection_protocol} $out/hosted/pub.dartlang.org/webkit_inspection_protocol-1.2.0

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${xml} $out/hosted/pub.dartlang.org/xml-6.2.0

    mkdir -p $out/hosted/pub.dartlang.org
    ln -s ${yaml} $out/hosted/pub.dartlang.org/yaml-3.1.1
'';

}