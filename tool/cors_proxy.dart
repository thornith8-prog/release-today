import 'dart:io';

const String _targetBase = 'https://news-ai-d115c798.fastapicloud.dev';
const int _port = 8787;

bool _isAllowedOrigin(String? origin) {
  if (origin == null) return false;
  final uri = Uri.tryParse(origin);
  if (uri == null) return false;
  return (uri.scheme == 'http' || uri.scheme == 'https') &&
      (uri.host == 'localhost' || uri.host == '127.0.0.1');
}

void _setSecurityAndCorsHeaders(HttpResponse res, String? origin) {
  if (_isAllowedOrigin(origin)) {
    res.headers.set('Access-Control-Allow-Origin', origin!);
    res.headers.set('Vary', 'Origin');
  }
  res.headers.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.headers.set('Access-Control-Allow-Headers',
      'Content-Type, Accept, Authorization, X-User-Id');
  res.headers.set('X-Content-Type-Options', 'nosniff');
  res.headers.set('X-Frame-Options', 'DENY');
}

/// Paths the proxy is allowed to forward.
bool _isAllowedPath(String path) {
  const allowedPrefixes = [
    '/articles',
    '/search',
    '/health',
    '/recommendations',
    '/partners',
    '/settings',
    '/auth/',
    '/search-topic/',
  ];
  return allowedPrefixes.any(path.startsWith);
}

Future<void> main() async {
  final client = HttpClient();
  // Bind strictly to 127.0.0.1 (loopback) for local development.
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, _port);
  stdout.writeln(
      'Local CORS proxy listening on http://127.0.0.1:$_port -> $_targetBase');

  await for (final HttpRequest req in server) {
    final origin = req.headers.value('origin');
    final res = req.response;
    _setSecurityAndCorsHeaders(res, origin);

    final method = req.method.toUpperCase();
    if (method == 'OPTIONS') {
      res.statusCode = HttpStatus.noContent;
      await res.close();
      continue;
    }

    if (method != 'GET' && method != 'POST') {
      res.statusCode = HttpStatus.methodNotAllowed;
      await res.close();
      continue;
    }

    final path = req.uri.path;
    if (!_isAllowedPath(path)) {
      res.statusCode = HttpStatus.forbidden;
      await res.close();
      continue;
    }

    try {
      final targetUri = Uri.parse(_targetBase).replace(
        path: req.uri.path,
        query: req.uri.hasQuery ? req.uri.query : null,
      );

      if (method == 'GET') {
        final upstreamReq = await client.getUrl(targetUri);
        upstreamReq.followRedirects = true;
        upstreamReq.headers.set(HttpHeaders.acceptHeader, 'application/json');
        // Forward the Authorization header when present.
        final authHeader = req.headers.value('authorization');
        if (authHeader != null) {
          upstreamReq.headers.set(HttpHeaders.authorizationHeader, authHeader);
        }
        final userIdHeader = req.headers.value('x-user-id');
        if (userIdHeader != null) {
          upstreamReq.headers.set('X-User-Id', userIdHeader);
        }

        final upstreamRes = await upstreamReq.close();
        res.statusCode = upstreamRes.statusCode;
        final contentType = upstreamRes.headers.contentType;
        if (contentType != null) {
          res.headers.contentType = contentType;
        }
        await upstreamRes.pipe(res);
      } else {
        // POST
        final upstreamReq = await client.postUrl(targetUri);
        upstreamReq.followRedirects = true;
        upstreamReq.headers
            .set(HttpHeaders.contentTypeHeader, 'application/json');
        upstreamReq.headers.set(HttpHeaders.acceptHeader, 'application/json');
        final authHeader = req.headers.value('authorization');
        if (authHeader != null) {
          upstreamReq.headers.set(HttpHeaders.authorizationHeader, authHeader);
        }
        final userIdHeader = req.headers.value('x-user-id');
        if (userIdHeader != null) {
          upstreamReq.headers.set('X-User-Id', userIdHeader);
        }
        // Forward the request body to upstream.
        final bodyBytes = await req.fold<List<int>>(
            <int>[], (prev, chunk) => prev..addAll(chunk));
        upstreamReq.add(bodyBytes);
        final upstreamRes = await upstreamReq.close();
        res.statusCode = upstreamRes.statusCode;
        final contentType = upstreamRes.headers.contentType;
        if (contentType != null) {
          res.headers.contentType = contentType;
        }
        await upstreamRes.pipe(res);
      }
    } catch (e) {
      res.statusCode = HttpStatus.badGateway;
      res.headers.contentType = ContentType.json;
      res.write('{"detail":"Proxy error: $e"}');
      await res.close();
    }
  }
}
