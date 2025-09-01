// Apenas para Web
void clearUrl() {
  // Import 'dart:html' só será feito aqui
  import 'dart:html' as html;
  html.window.history.pushState(null, 'Rua11Store', '/');
}
