import 'package:path/path.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';

import 'global.dart';
import 'purge.dart';

class API {
  final Purge purge = Purge();
  final Router router = Router();

  Future<Response> onStop(Request request) async {
    final bool succeed = purge.stop();
    final bool running = purge.isRunning;
    final String message = 'purge: stop=$succeed, running=$running';
    print(message);
    return Response.ok(message);
  }

  Future<Response> onStart(Request request) async {
    final bool succeed = purge.start();
    final bool running = purge.isRunning;
    final String message = 'purge: start=$succeed, running=$running, root=${purge.root}';
    print(message);
    return Response.ok(message);
  }

  Handler v1({String root}) {
    try {
      final String ver1 = "v1";
      router.get(uri('stop'), onStop);
      router.get(uri('start'), onStart);
      router.get(uri('stop', version: ver1), onStop);
      router.get(uri('start', version: ver1), onStart);

      final String dcache = Global.currentPath;
      final Handler index = createStaticHandler(dcache, defaultDocument: Global.indexName);
      final Handler favicon = createStaticHandler(dcache, defaultDocument: Global.faviconName);
      final Handler cascade = Cascade().add(index).add(favicon).add(router.handler).handler;
      final Handler handler = Pipeline().addMiddleware(logRequests()).addHandler(cascade);
      return handler;
    }
    catch (exc) {
      print('v1: $exc');
    }
    finally {
      purge.root = root;
      purge.start();
    }
    final Handler defaultHandler = Pipeline().addHandler((Request request) {
      return Response.ok('Request for ${request.url}');
    });
    return defaultHandler;
  }

  String uri(String path, {String version}) {
    if (version == null)
      return join('/', path);
    return join('/', version, path);
  }
}
