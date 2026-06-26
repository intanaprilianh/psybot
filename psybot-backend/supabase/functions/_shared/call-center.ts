export interface CallCenterService {
  id: string;
  nama: string;
  deskripsi: string;
  nomor: string;
  jam_operasional: string;
  tipe: 'telepon' | 'chat' | 'whatsapp';
  gratis: boolean;
  url?: string;
}

export const CALL_CENTER_SERVICES: CallCenterService[] = [
  {
    id: 'kemenkes_119',
    nama: 'Hotline Kemenkes RI',
    deskripsi: 'Layanan darurat kesehatan termasuk krisis mental, tersedia 24 jam',
    nomor: 'tel:119',
    jam_operasional: '24 jam / 7 hari',
    tipe: 'telepon',
    gratis: true,
  },
  {
    id: 'into_the_light',
    nama: 'Into The Light Indonesia',
    deskripsi: 'Layanan pencegahan bunuh diri dan dukungan kesehatan mental',
    nomor: 'tel:119',
    jam_operasional: '24 jam (ext 8)',
    tipe: 'telepon',
    gratis: true,
    url: 'https://www.intothelightid.org',
  },
  {
    id: 'yayasan_pulih',
    nama: 'Yayasan Pulih',
    deskripsi: 'Konseling psikologis dan dukungan mental health',
    nomor: 'tel:+62217884258',
    jam_operasional: 'Senin-Jumat 09.00-17.00',
    tipe: 'telepon',
    gratis: false,
    url: 'https://www.yayasanpulih.org',
  },
  {
    id: 'sebaya_id',
    nama: 'Sebaya.id',
    deskripsi: 'Dukungan sebaya untuk kesehatan mental remaja dan mahasiswa',
    nomor: 'tel:+6281287877788',
    jam_operasional: 'Senin-Sabtu 08.00-22.00',
    tipe: 'whatsapp',
    gratis: true,
    url: 'https://www.sebaya.id',
  },
  {
    id: 'rsj_cisarua',
    nama: 'RSJ Amino Gondohutomo (Jawa Tengah)',
    deskripsi: 'Hotline Rumah Sakit Jiwa Provinsi',
    nomor: 'tel:+62245860038',
    jam_operasional: '24 jam',
    tipe: 'telepon',
    gratis: false,
  },
];

export function getServicesForRiskLevel(level: 'high' | 'critical'): CallCenterService[] {
  if (level === 'critical') {
    return CALL_CENTER_SERVICES.filter(s =>
      s.jam_operasional.includes('24 jam') || s.id === 'into_the_light'
    );
  }
  return CALL_CENTER_SERVICES;
}
