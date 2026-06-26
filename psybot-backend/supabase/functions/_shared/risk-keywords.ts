export const CRITICAL_KEYWORDS = [
  // Ungkapan langsung
  'bunuh diri', 'mau mati', 'ingin mati', 'sudah mau mati', 'tidak mau hidup lagi',
  'mengakhiri hidup', 'akhiri hidup', 'tidak ada gunanya hidup', 'lebih baik mati',
  'kapan aku mati', 'mau bunuh diri', 'mo bunuh diri', 'pengen bunuh diri', 'pengen mati aja',
  'nggak mau hidup lagi', 'gak mau hidup lagi', 'ga mau hidup lagi',
  'nggak kuat menjalani hidup', 'gak kuat menjalani hidup', 'tidak kuat menjalani hidup',
  'tired of living', 'end my life', 'kill myself',

  // Menyakiti diri
  'nyakitin diri', 'menyakiti diri', 'mau nyakitin diri sendiri',
  'potong diri', 'bakar diri', 'banting diri',
  'lukai diri', 'melukai diri',

  // Ungkapan tidak langsung (tanda peringatan)
  'merepotkan siapa-siapa lagi', 'nggak akan merepotkan siapa', 'tidak akan merepotkan siapa',
  'tidak perlu khawatir tentang aku lagi', 'nggak perlu khawatir tentang aku lagi',
  'ini perpisahan', 'sudah berdamai dengan semuanya', 'sudah menyiapkan semuanya',
  'semua masalahku selesai', 'masalahku selesai', 'masalahku akan selesai',
  'besok nggak bangun lagi', 'besok gak bangun lagi', 'besok tidak bangun lagi',
  'kalau aku nggak ada', 'kalau aku tidak ada', 'kalau aku gak ada',
  'hidup kalian pasti lebih mudah', 'hidup kalian pasti lebih baik',
  'pergi ke surga', 'pergi ke neraka',
  'ingin menghilang', 'pengen menghilang', 'mau menghilang',
  'ga punya masa depan', 'gak punya masa depan', 'nggak punya masa depan', 'tidak punya masa depan',
  'cuma beban buat semua orang', 'cuman jadi beban', 'cuma jadi beban',
];

export const HIGH_RISK_KEYWORDS = [
  'hopeless', 'tidak ada harapan',
  'sendirian terus', 'tidak ada yang mau', 'tidak berguna',
  'beban buat semua', 'semua lebih baik tanpa aku',
  'sudah tidak kuat', 'tidak sanggup lagi', 'menyerah',
  'putus asa', 'cape banget hidup', 'capek hidup',
];

export const MEDIUM_RISK_KEYWORDS = [
  'sedih banget', 'nangis terus', 'tidak bisa tidur',
  'tidak nafsu makan', 'panic attack', 'anxiety',
  'depresi', 'galau banget', 'stress banget',
  // Ungkapan ambigu: tidak memicu panggilan, tapi AI membalas dengan hati-hati
  'ingin lebih tenang', 'tidak percaya takdir', 'benci tuhan', 'tidak ada yang peduli',
];

export type RiskLevel = 'critical' | 'high' | 'medium' | 'low';

export function detectRiskFromText(text: string): {
  level: RiskLevel;
  triggeredKeywords: string[];
} {
  const lowerText = text.toLowerCase();
  const triggered: string[] = [];

  for (const kw of CRITICAL_KEYWORDS) {
    if (lowerText.includes(kw)) triggered.push(kw);
  }
  if (triggered.length > 0) return { level: 'critical', triggeredKeywords: triggered };

  for (const kw of HIGH_RISK_KEYWORDS) {
    if (lowerText.includes(kw)) triggered.push(kw);
  }
  if (triggered.length > 0) return { level: 'high', triggeredKeywords: triggered };

  for (const kw of MEDIUM_RISK_KEYWORDS) {
    if (lowerText.includes(kw)) triggered.push(kw);
  }
  if (triggered.length > 0) return { level: 'medium', triggeredKeywords: triggered };

  return { level: 'low', triggeredKeywords: [] };
}
