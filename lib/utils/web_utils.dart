import 'dart:html' as html;

// Apenas para Web
void clearUrl() {
  // Import 'dart:html' só será feito aqui

  html.window.history.pushState(null, 'Demo Store', '/');
}
