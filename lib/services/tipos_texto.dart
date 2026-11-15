enum TipoTexto {
  normal,                 // 1
  rubrica,                // 2
  semirrubrica,           // 3
  rubricaCentrada,        // 4
  rubricaCentradaNegritaMayusculas, // 5
  pueblo,                 // 6
  coro,                   // 7
  titulo,                 // 8
  indicacionPueblo,       // 9: «EL PUEBLO DE PIE»…, en violeta
}

TipoTexto parseTipo(dynamic raw) {
  if (raw is int) {
    final i = raw - 1; // los datos vienen 1..9 → enum 0..8
    if (i < 0 || i >= TipoTexto.values.length) return TipoTexto.normal;
    return TipoTexto.values[i];
  }
  if (raw is String) {
    // por si algún día guardas strings
    switch (raw) {
      case 'normal': return TipoTexto.normal;
      case 'rubrica': return TipoTexto.rubrica;
      case 'semirrubrica': return TipoTexto.semirrubrica;
      case 'rubricaCentrada': return TipoTexto.rubricaCentrada;
      case 'rubricaCentradaNegritaMayusculas': return TipoTexto.rubricaCentradaNegritaMayusculas;
      case 'pueblo': return TipoTexto.pueblo;
      case 'coro': return TipoTexto.coro;
      case 'titulo': return TipoTexto.titulo;
      case 'indicacionPueblo': return TipoTexto.indicacionPueblo;
    }
  }
  return TipoTexto.normal;
}