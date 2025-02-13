## Introducción
Este proyecto permite compilar e instalar OpenSSH de manera **estáticamente enlazada** utilizando **musl**. 
Se compilan las dependencias necesarias (**Zlib, OpenSSL, OpenSSH**) de forma estática para facilitar la 
portabilidad del binario.

### Dependencias necesarias
El script `deps.sh` instala las dependencias necesarias para compilar el entorno:
```sh
sudo ./deps.sh
```
Si se desea compilar el entorno **musl**, se debe responder **"y"** cuando el script lo solicite e introducir 
la arquitectura que vas a utilizar.

## Descripción de los Scripts

### 1. `static-musl.sh`
Este script compila **Zlib, OpenSSL y OpenSSH**.

#### **Uso:**
```sh
./static-musl.sh
```
''
#### **Pasos que realiza:**
1. Configura los directorios de instalación y compilación.
2. Descarga, compila e instala **Zlib** (opcional).
3. Descarga, compila e instala **OpenSSL** (opcional).  
4. Descarga, compila e instala **OpenSSH**.
5. Al finalizar, OpenSSH estático estará en **`/opt/openssh/sbin`**.


### 2. `deps.sh`
Instala todas las dependencias necesarias para compilar el proyecto, incluyendo herramientas como `gcc`, `make`, `perl`, `autoconf`, etc.

#### **Uso:**
```sh
sudo ./deps.sh
```

Si se desea compilar el entorno **musl**, el script solicitará la selección de la arquitectura y procederá a la compilación.


### 3. `build.sh`
Este script permite **limpiar** los archivos de compilación o **crear un paquete** comprimido con la compilación completa.

#### **Uso:**
Para limpiar archivos generados:
```sh
sudo ./build.sh clean
```

Para crear un paquete `tar.gz` de OpenSSH compilado:
```sh
sudo ./build.sh create
```
El paquete se guardará en el directorio `root/` dentro del proyecto.


## Ubicaciones de los archivos generados
- **OpenSSH compilado:** `/opt/openssh/sbin/sshd`
- **Paquete comprimido:** `root/openssh.tgz`

## Notas Adicionales
- Las herramientas de compilación cruzada son: [Musl Cross Make](https://github.com/richfelker/musl-cross-make)
- El script `static-musl.sh` verifica si los binarios ya estan compilados antes de recompilar.
- Todos los scripts usan **sudo**, pero se puede adaptar a doas, su, etc.
- En caso de errores, asegúrate de que todas las dependencias estén instaladas y revisa los mensajes de salida.
- Si no utilizas una distribucion derivada de debian tienes que instalar las dependencias de forma manual o adaptarlo en `deps.sh`.
