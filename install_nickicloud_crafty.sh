#!/bin/bash
# ==========================================================
# NickiCloud Crafty Controller 4 Installer (Debian 13)
# v3 - 2025-10-21
# ==========================================================

set -e

INSTALL_DIR="/home/nicki/crafty"
BRAND_NAME="NickiCloud"
BRAND_DOMAIN="nickicloud.de"
CRAFTY_REPO="https://gitlab.com/crafty-controller/crafty-4.git"

echo "=========================================================="
echo "   🚀 $BRAND_NAME Crafty Controller 4 Setup startet..."
echo "   Installationspfad: $INSTALL_DIR"
echo "=========================================================="
sleep 1

# --- Pakete installieren ---
echo "📦 Installiere Voraussetzungen..."
sudo apt update -y
sudo apt install -y git python3 python3-venv python3-pip nodejs npm

# --- Repository vorbereiten ---
if [ ! -d "$INSTALL_DIR/.git" ]; then
  echo "⬇️ Klone Crafty Controller..."
  git clone "$CRAFTY_REPO" "$INSTALL_DIR"
else
  echo "🔄 Aktualisiere bestehendes Repo..."
  cd "$INSTALL_DIR"
  git pull
fi

cd "$INSTALL_DIR"

# --- Virtuelle Umgebung ---
echo "🐍 Erstelle Python-Umgebung..."
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip

# --- Anforderungen installieren, falls vorhanden ---
if [ -f "requirements.txt" ]; then
  echo "📚 Installiere Python-Abhängigkeiten..."
  pip install -r requirements.txt || true
fi

# --- Werbung entfernen und Branding einfügen ---
echo "🧹 Entferne Werbung & füge Branding hinzu..."
find . -type f \( -name "*.html" -o -name "*.vue" -o -name "*.js" \) | while read -r file; do
  sed -i "s/Sponsored by.*/Powered by $BRAND_NAME \- $BRAND_DOMAIN/g" "$file" || true
  sed -i "s/advertisement//g" "$file" || true
  sed -i "s/AdBanner//g" "$file" || true
done

# --- Frontend bauen ---
if [ -d "frontend" ]; then
  echo "⚙️ Baue Frontend..."
  cd frontend
  npm install
  npm run build || echo "⚠️ Build Warnung – ggf. manuell prüfen"
  cd ..
fi

# --- Hauptdatei suchen ---
echo "🔍 Suche Startdatei..."
if [ -f "src/main.py" ]; then
  MAIN_FILE="src/main.py"
elif [ -f "crafty/app/main.py" ]; then
  MAIN_FILE="crafty/app/main.py"
else
  echo "❌ Konnte main.py nicht finden – bitte Pfad manuell prüfen."
  exit 1
fi

# --- Start- und Stop-Skripte erstellen ---
echo "🛠️ Erstelle start.sh und stop.sh..."

cat << EOF > start.sh
#!/bin/bash
cd "\$(dirname "\$0")"
source venv/bin/activate
echo "🚀 Starte Crafty Controller (NickiCloud Edition)..."
python3 $MAIN_FILE
EOF

cat << 'EOF' > stop.sh
#!/bin/bash
echo "🛑 Stoppe Crafty Controller..."
pkill -f "python3 .*main.py" || echo "Kein laufender Crafty-Prozess gefunden."
EOF

chmod +x start.sh stop.sh

# --- Branding im Footer (optional) ---
if [ -f "web/templates/base.html" ]; then
  sed -i "/<\/footer>/i <p style='text-align:center;color:#aaa;'>Powered by NickiCloud – <a href='https:\/\/nickicloud.de'>nickicloud.de<\/a><\/p>" web/templates/base.html
fi

# --- Fertig ---
echo "=========================================================="
echo "✅ Installation abgeschlossen!"
echo ""
echo "Starte Crafty mit:"
echo "   cd $INSTALL_DIR && ./start.sh"
echo ""
echo "Beende Crafty mit:"
echo "   ./stop.sh"
echo ""
echo "Webinterface: https://<deine-server-ip>:8443"
echo ""
echo "Branding: $BRAND_NAME ($BRAND_DOMAIN)"
echo "=========================================================="
