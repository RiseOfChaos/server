import 'package:jaguar/jaguar.dart';
import 'package:jaguar_dev_proxy/jaguar_dev_proxy.dart';

main() {
  final server = Jaguar(port: 8000);
  server.staticFiles('/static/*', '../static/');
  server.addRoute(getOnlyProxy('/web/', 'http://localhost:8080/'));
  server.log.onRecord.listen(print);
  server.serve(logRequests: true);
}
