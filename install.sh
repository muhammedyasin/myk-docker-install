#!/bin/bash

set -e

echo "🚀 Docker kurulumu başlıyor..."

# Root kontrolü
if [ "$EUID" -ne 0 ]; then
  echo "❌ Lütfen root olarak çalıştırın (sudo ile)"
  exit 1
fi

# Sistem tipi
OS=$(grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')

echo "📦 OS tespit edildi: $OS"

# Eski dockerları kaldır
echo "🧹 Eski Docker versiyonları temizleniyor..."
apt-get remove -y docker docker-engine docker.io containerd runc || true

# Paketler
echo "📦 Gerekli paketler yükleniyor..."
apt-get update -y
apt-get install -y ca-certificates curl gnupg lsb-release

# GPG key
echo "🔑 Docker GPG key ekleniyor..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/$OS/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Repo ekle
echo "📦 Docker repo ekleniyor..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$OS \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Kurulum
echo "🐳 Docker kuruluyor..."
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Servis başlat
echo "⚙️ Docker servisi başlatılıyor..."
systemctl enable docker
systemctl start docker

# Kullanıcıyı docker grubuna ekle
if [ -n "$SUDO_USER" ]; then
  echo "👤 Kullanıcı docker grubuna ekleniyor: $SUDO_USER"
  usermod -aG docker $SUDO_USER
fi

# Test
echo "🧪 Test container çalıştırılıyor..."
docker run hello-world || true

echo ""
echo "✅ Docker kurulumu tamamlandı!"
echo "⚠️ Docker grubunun aktif olması için çıkış yapıp tekrar girmen gerekir."
echo "👉 docker --version"
echo "👉 docker compose version"
