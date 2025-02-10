#!/bin/bash
#
# Script para la instalacion de dependencias y compilar el entorno de compilacion Musl
#

#---------------------------------------------------------
# Instalación de dependencias necesarias para compilar
#---------------------------------------------------------

# Lista de dependencias requeridas
DEPS=(
  build-essential
  autoconf
  binutils
  bison
  flex
  git
  perl
  curl
  xz-utils
  zlib1g-dev
  libssl-dev
)

echo "Actualizando repositorios..."
sudo apt update

echo "Instalando dependencias necesarias..."
sudo apt install -y "${DEPS[@]}"

echo "Verificando la instalación de cada paquete:"
for pkg in "${DEPS[@]}"; do
    if dpkg -s "$pkg" >/dev/null 2>&1; then
        echo "[$pkg] instalado."
    else
        echo "[$pkg] FALTA."
    fi
done

#---------------------------------------------------------
# Instalación del entorno de compilación Musl (musl-cross-make)
#---------------------------------------------------------

# Solicitar si se desea compilar el entorno Musl
read -r -p "¿Instalar entorno de compilación Musl? (y/N): " musl_choice

# Función para seleccionar la arquitectura y compilar musl-cross-make
arch_compiler() {
  echo "Las arquitecturas soportadas son (elige una):"
  cat << EOF
    aarch64[_be]-linux-musl
    arm[eb]-linux-musleabi[hf]
    i*86-linux-musl
    microblaze[el]-linux-musl
    mips-linux-musl
    mips[el]-linux-musl[sf]
    mips64[el]-linux-musl[n32][sf]
    powerpc-linux-musl[sf]
    powerpc64[le]-linux-musl
    riscv64-linux-musl
    s390x-linux-musl
    sh*[eb]-linux-musl[fdpic][sf]
    x86_64-linux-musl[x32]
EOF

  read -r -p "Introduce la arquitectura deseada: " arch

  # Clonar el repositorio de musl-cross-make si no existe
  if [ ! -d "musl-cross-make" ]; then
      git clone https://github.com/richfelker/musl-cross-make.git
      cd musl-cross-make || { echo "No se pudo acceder a musl-cross-make"; exit 1; }
  else 
      cd musl-cross-make || { echo "No se pudo acceder a musl-cross-make"; exit 1; }
      make clean
  fi

  echo "TARGET = $arch" > config.mak

  echo "Compilando Musl para $arch..."
  make -j$(nproc)

  # Definir el directorio de instalación (se usará en /opt)
  OUTPUT="/opt/musl-$arch"
  sudo mkdir -p "$OUTPUT"
  sudo make install OUTPUT="$OUTPUT"

  # Agregar los binarios al PATH 
  echo "export PATH=\$PATH:$OUTPUT/bin" | tee -a $HOME/.bashrc
  source $HOME/.bashrc || source $HOME/.profile

  echo "¡Entorno de compilación Musl para $arch instalado en $OUTPUT!"
  cd "$OLDPWD" || exit 1
}

compile_musl_cross() {
   case "$musl_choice" in
       y|Y|s|S|Yes|yes)
          arch_compiler
          ;;
       n|N|No|no|"")
          echo "Instalación de Musl cancelada."
          ;;
       *)
          echo "Opción no válida. Saliendo..."
          exit 1
          ;;
   esac
}

compile_musl_cross

echo "Instalación de dependencias y compilación de Musl completadas."

