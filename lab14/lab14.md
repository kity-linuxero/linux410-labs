# Laboratorio 14 - Scripts de administración

## Objetivo

- Escribir un script, darle permiso de ejecución y ejecutarlo.
- Armar de a un paso un script que copia los registros de apt: variables, argumento, `if`, código de salida, mensajes de error y `logger`.
- Probarlo con los casos que fallan: sin argumento, con un directorio que no existe, sin `sudo` y con el disco lleno.
- Dejarlo instalado en `/usr/local/sbin` con los permisos correctos.

### Punto de partida

Usamos la VM Debian 13 del curso con la cuenta administradora, por ejemplo `cristian`, y el acceso por SSH del [Laboratorio 3](../lab3/lab3.md). No hace falta haber hecho otros laboratorios: lo que se necesita se arma acá y se deshace al final.

> [!NOTE]
> Reemplazá `cristian` por tu usuario. Las fechas, las horas, los tamaños y los números de proceso de las salidas van a ser otros en tu VM.

## 0. Preparación

Desde la máquina anfitriona:

```bash
ssh -p 2222 cristian@localhost
```

Creá un directorio para los scripts del laboratorio y entrá:

```bash
mkdir -p ~/scripts
cd ~/scripts
```

## 1. El primer script

Abrí un archivo nuevo con `nano`:

```bash
nano estado.sh
```

Escribí:

```bash
#!/bin/bash
# Estado del equipo

df -h /
free -h
uptime
```

Guardá con `Ctrl+O` y `Enter`, y salí con `Ctrl+X`.

La primera línea dice qué programa lee el archivo. El resto son comandos que ya conocés, uno debajo del otro.

### 1. Ejecutarlo con bash

```bash
bash estado.sh
```

```text
S.ficheros     Tamaño Usados  Disp Uso% Montado en
/dev/sda2         19G   1,6G   17G   9% /
               total       usado       libre  compartido   búf/caché  disponible
Mem:           948Mi       225Mi       699Mi       548Ki       153Mi       722Mi
Inter:            0B          0B          0B
 00:42:38 up  3:56,  1 user,  load average: 0,00, 0,00, 0,00
```

Los tres comandos se ejecutaron en orden.

### 2. Ejecutarlo por su nombre

```bash
./estado.sh
```

```text
-bash: ./estado.sh: Permiso denegado
```

`nano` crea los archivos sin permiso de ejecución. Agregalo y probá de nuevo:

```bash
chmod +x estado.sh
./estado.sh
```

Ahora sí muestra lo mismo que con `bash`. El `./` hace falta porque el directorio actual no está en el `PATH`.

## 2. Un lugar para las copias

El script que vamos a escribir copia los registros de apt a `/srv/respaldos`. Para poder llenarlo más adelante sin tocar los discos de la VM, lo armamos en memoria con `tmpfs`, igual que en el [Laboratorio 13.1](../lab13/lab13.1.md). `size=5M` le pone un límite de 5 MB:

```bash
sudo mkdir -p /srv/respaldos
sudo mount -t tmpfs -o size=5M tmpfs /srv/respaldos
df -h /srv/respaldos
```

```text
S.ficheros     Tamaño Usados  Disp Uso% Montado en
tmpfs            5,0M      0  5,0M   0% /srv/respaldos
```

## 3. El script, de a un paso

### 1. Primera versión: variables

```bash
nano archivar.sh
```

```bash
#!/bin/bash
# Copia los registros de apt en /srv/respaldos

DESTINO=/srv/respaldos
FECHA=$(date +%F)

cp -r /var/log/apt "$DESTINO/apt-$FECHA"
echo "Listo: $DESTINO/apt-$FECHA"
```

- `DESTINO` y `FECHA` son variables. Se asignan sin espacios alrededor del `=` y se leen con `$`.
- `$(date +%F)` guarda en la variable la fecha de hoy, en formato año-mes-día.
- Las variables van entre comillas dobles cuando se usan.

Dale permiso y ejecutalo con `sudo`, porque `/srv/respaldos` es de `root`:

```bash
chmod +x archivar.sh
sudo ./archivar.sh
ls /srv/respaldos/apt-*
```

```text
Listo: /srv/respaldos/apt-2026-10-26
eipp.log.xz
history.log
history.log.1.gz
term.log
term.log.1.gz
```

Borrá la copia antes de seguir. Si la carpeta ya existe, `cp -r` copia adentro y crea `apt-2026-10-26/apt`:

```bash
sudo rm -r /srv/respaldos/apt-*
```

### 2. Segunda versión: un argumento y dos controles

El destino fijo sirve para un solo caso. Que lo reciba como argumento. Abrí el script y cambiá la línea de `DESTINO` por `$1`, y agregá los dos `if` antes del `cp`:

```bash
#!/bin/bash
# Copia los registros de apt en el directorio que se indica

DESTINO=$1
FECHA=$(date +%F)

if [ -z "$DESTINO" ]; then
    echo "Uso: $0 directorio" >&2
    exit 1
fi

if [ ! -d "$DESTINO" ]; then
    echo "No existe el directorio $DESTINO" >&2
    exit 1
fi

cp -r /var/log/apt "$DESTINO/apt-$FECHA"
echo "Listo: $DESTINO/apt-$FECHA"
```

- `$1` es lo que escribimos después del nombre del script.
- `[ -z "$DESTINO" ]` se cumple si la variable está vacía, o sea, si no pasamos argumento.
- `[ ! -d "$DESTINO" ]` se cumple si no es un directorio.
- `>&2` manda el mensaje por la salida de error y `exit 1` termina el script avisando que algo salió mal.

Probá los dos controles y mirá el código de salida de cada uno:

```bash
./archivar.sh; echo "código: $?"
./archivar.sh /noexiste; echo "código: $?"
```

```text
Uso: ./archivar.sh directorio
código: 1
No existe el directorio /noexiste
código: 1
```

En los dos casos el script se detuvo antes del `cp`, sin tocar nada.

### 3. Tercera versión: avisar si la copia falla

Falta saber si el `cp` funcionó. Agregá, después del `cp`, un `if` que mire `$?`, y cambiá el final para dejar rastro en el log:

```bash
#!/bin/bash
# Copia los registros de apt en el directorio que se indica

DESTINO=$1
FECHA=$(date +%F)

if [ -z "$DESTINO" ]; then
    echo "Uso: $0 directorio" >&2
    exit 1
fi

if [ ! -d "$DESTINO" ]; then
    echo "No existe el directorio $DESTINO" >&2
    exit 1
fi

cp -r /var/log/apt "$DESTINO/apt-$FECHA"

if [ $? -ne 0 ]; then
    echo "No se pudo copiar" >&2
    logger -t archivar -p user.err "Falló la copia en $DESTINO"
    exit 1
fi

echo "Listo: $DESTINO/apt-$FECHA"
logger -t archivar "Copia en $DESTINO"
```

- `$?` es el código de salida del último comando: `0` si salió bien. Entre el `cp` y el `if` no puede haber otra línea.
- `logger -t archivar` escribe en el log con la etiqueta `archivar`, como en la [clase 14](https://linux.idepba.com.ar/clase14.html).

Antes de probarlo, revisá que no haya errores de sintaxis:

```bash
bash -n archivar.sh
```

Si no muestra nada, está bien escrito. Si falta un `fi`, avisa en qué línea.

## 4. Probar los casos

### 1. Todo bien

```bash
sudo ./archivar.sh /srv/respaldos; echo "código: $?"
```

```text
Listo: /srv/respaldos/apt-2026-10-26
código: 0
```

Borrá la copia para la próxima prueba:

```bash
sudo rm -r /srv/respaldos/apt-*
```

### 2. Sin sudo

Probalo sin `sudo`, con un directorio tuyo como destino:

```bash
mkdir -p ~/prueba
./archivar.sh ~/prueba; echo "código: $?"
```

```text
cp: no se puede abrir '/var/log/apt/term.log' para lectura: Permiso denegado
cp: no se puede abrir '/var/log/apt/term.log.1.gz' para lectura: Permiso denegado
No se pudo copiar
código: 1
```

Nadie provocó este error: `term.log` es de `root:adm` con modo 640 y tu cuenta no lo puede leer. El script lo detectó por el código de salida de `cp`. Mirá qué quedó en el destino:

```bash
ls ~/prueba/apt-*
```

```text
eipp.log.xz
history.log
history.log.1.gz
```

Quedó una copia a medias, sin `term.log`. Por eso hay que revisar si el comando funcionó: el directorio existe, pero la copia está incompleta. Borralo:

```bash
rm -r ~/prueba
```

### 3. Disco lleno

Llená `/srv/respaldos` con un archivo de ceros. `dd` escribe hasta que no entra más, así que su error es lo esperado:

```bash
sudo dd if=/dev/zero of=/srv/respaldos/relleno.bin bs=1M status=none
df -h /srv/respaldos
```

```text
dd: error al escribir en '/srv/respaldos/relleno.bin': No queda espacio en el dispositivo
S.ficheros     Tamaño Usados  Disp Uso% Montado en
tmpfs            5,0M   5,0M     0 100% /srv/respaldos
```

Ejecutá el script:

```bash
sudo ./archivar.sh /srv/respaldos; echo "código: $?"
```

```text
cp: error al escribir en '/srv/respaldos/apt-2026-10-26/eipp.log.xz': No queda espacio en el dispositivo
cp: error al escribir en '/srv/respaldos/apt-2026-10-26/history.log': No queda espacio en el dispositivo
cp: error al escribir en '/srv/respaldos/apt-2026-10-26/term.log': No queda espacio en el dispositivo
cp: error al escribir en '/srv/respaldos/apt-2026-10-26/term.log.1.gz': No queda espacio en el dispositivo
cp: error al escribir en '/srv/respaldos/apt-2026-10-26/history.log.1.gz': No queda espacio en el dispositivo
No se pudo copiar
código: 1
```

```bash
sudo ls -l /srv/respaldos/apt-*
```

```text
total 0
-rw-r--r-- 1 root root 0 oct 26 00:42 eipp.log.xz
-rw-r--r-- 1 root root 0 oct 26 00:42 history.log
-rw-r--r-- 1 root root 0 oct 26 00:42 history.log.1.gz
-rw-r----- 1 root root 0 oct 26 00:42 term.log
-rw-r----- 1 root root 0 oct 26 00:42 term.log.1.gz
```

Están todos los nombres, pero con 0 bytes. Alguien que mire el directorio podría creer que hay una copia.

### 4. Leer el log

```bash
journalctl -t archivar --since "20 min ago"
sudo journalctl -t archivar --since "20 min ago"
```

```text
Hint: You are currently not seeing messages from other users and the system.
      Users in groups 'adm', 'systemd-journal' can see all messages.
      Pass -q to turn off this notice.
oct 26 00:42:38 lab2-vm archivar[1887]: Falló la copia en /home/cristian/prueba
oct 26 00:42:38 lab2-vm archivar[1878]: Copia en /srv/respaldos
oct 26 00:42:38 lab2-vm archivar[1887]: Falló la copia en /home/cristian/prueba
oct 26 00:42:38 lab2-vm archivar[1899]: Falló la copia en /srv/respaldos
```

Sin `sudo` ves solo el mensaje que escribiste con tu cuenta. Los que escribió el script ejecutado con `sudo` son de `root`, y para verlos hace falta `sudo`.

Limpiá el relleno y la copia rota:

```bash
sudo rm -r /srv/respaldos/relleno.bin /srv/respaldos/apt-*
```

### 5. Ver cada paso con bash -x

```bash
bash -x ./archivar.sh /noexiste
```

```text
+ DESTINO=/noexiste
++ date +%F
+ FECHA=2026-10-26
+ '[' -z /noexiste ']'
+ '[' '!' -d /noexiste ']'
+ echo 'No existe el directorio /noexiste'
No existe el directorio /noexiste
+ exit 1
```

Cada línea con `+` es lo que ejecutó la shell, con las variables ya reemplazadas. Sirve para ver en qué paso se detuvo y con qué valores.

## 5. Instalar el script

Los scripts del administrador van en `/usr/local/sbin`, con dueño `root` y modo 755: todos lo pueden ejecutar y solo `root` lo puede modificar.

```bash
sudo cp archivar.sh /usr/local/sbin/
sudo chown root:root /usr/local/sbin/archivar.sh
sudo chmod 755 /usr/local/sbin/archivar.sh
ls -l /usr/local/sbin/archivar.sh
```

```text
-rwxr-xr-x 1 root root 521 oct 26 00:42 /usr/local/sbin/archivar.sh
```

Ahora se ejecuta por su nombre, sin `./`:

```bash
sudo archivar.sh /srv/respaldos; echo "código: $?"
archivar.sh /srv/respaldos
```

```text
Listo: /srv/respaldos/apt-2026-10-26
código: 0
-bash: archivar.sh: orden no encontrada
```

Con `sudo` lo encuentra y sin `sudo` no: `/usr/local/sbin` está en el `PATH` de `sudo`, pero no en el de tu cuenta. Comparalos:

```bash
echo $PATH
sudo printenv PATH
```

```text
/usr/local/bin:/usr/bin:/bin:/usr/games
/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
```

Por último, comprobá que tu cuenta no lo puede modificar:

```bash
echo "# prueba" | tee -a /usr/local/sbin/archivar.sh
```

```text
tee: /usr/local/sbin/archivar.sh: Permiso denegado
```

Si una cuenta común pudiera editar un script que corre como `root`, podría hacer que `root` ejecute lo que quisiera.

## 6. Opcional: revisar el script con shellcheck

`shellcheck` lee un script sin ejecutarlo y avisa de errores comunes. Instalalo y pasalo sobre tu script:

```bash
sudo apt install shellcheck
shellcheck archivar.sh
```

```text
In archivar.sh line 19:
if [ $? -ne 0 ]; then
     ^-- SC2181 (style): Check exit code directly with e.g. 'if ! mycmd;', not indirectly with $?.

For more information:
  https://www.shellcheck.net/wiki/SC2181 -- Check exit code directly with e.g...
```

Es una sugerencia de estilo (`style`), no un error: propone escribir `if ! cp ...; then`, una forma más corta que vas a ver en scripts ajenos. Nuestra versión funciona igual.

Para ver un error de verdad, sacale las comillas a una variable en una copia del script y volvé a pasarlo:

```bash
sed 's/"\$DESTINO"/$DESTINO/' archivar.sh > sin-comillas.sh
shellcheck sin-comillas.sh
```

Ahora avisa `SC2086 (info): Double quote to prevent globbing and word splitting` y propone la versión con comillas. Si no lo vas a usar más, podés desinstalarlo con `sudo apt purge shellcheck`.

## 7. Opcional: revisar varios servicios

Un `for` repite los mismos comandos para cada elemento de una lista. Este script muestra el estado de varios servicios de una vez:

```bash
nano servicios.sh
```

```bash
#!/bin/bash
# Muestra el estado de varios servicios

for s in ssh cron systemd-timesyncd apache2; do
    echo "$s: $(systemctl is-active $s)"
done
```

```bash
chmod +x servicios.sh
./servicios.sh
```

```text
ssh: active
cron: active
systemd-timesyncd: active
apache2: inactive
```

`apache2` no está instalado y aun así responde `inactive`: `systemctl is-active` no distingue un servicio detenido de uno que no existe. Agregá a la lista algún servicio que te interese.

## 8. Limpieza

Desmontá `/srv/respaldos`. Lo que había adentro estaba en memoria y se pierde:

```bash
sudo umount /srv/respaldos
sudo rmdir /srv/respaldos
```

Podés dejar `/usr/local/sbin/archivar.sh` y `~/scripts`: el Laboratorio 15 programa este script para que se ejecute solo, y si no está, lo crea. Para borrarlo:

```bash
sudo rm /usr/local/sbin/archivar.sh
rm -r ~/scripts
```

## Preguntas

1. ¿Por qué `./estado.sh` dio `Permiso denegado` y `bash estado.sh` no?
2. En el caso sin `sudo`, el directorio `apt-...` existía al final. ¿Por qué el script igual dijo `No se pudo copiar`? ¿Qué habría pasado sin el `if [ $? -ne 0 ]`?
3. ¿Qué pasaría si en el `cp` usaras `$DESTINO` sin comillas y alguien pasara un directorio con un espacio en el nombre?
4. ¿Por qué el script instalado se ejecuta con `sudo archivar.sh` pero no con `archivar.sh`?
5. ¿Por qué no conviene que una cuenta común pueda modificar un script que se ejecuta como `root`?
6. Si el script dejara una copia a medias cuando falla, ¿cómo lo cambiarías para que la borre? ¿Qué cuidado hay que tener con ese `rm`?

## Resumen del laboratorio

- Un script es un archivo con comandos. La primera línea (`#!/bin/bash`) dice quién lo lee y `chmod +x` permite ejecutarlo con `./`.
- Las variables se asignan sin espacios y se usan entre comillas dobles. `$(comando)` guarda la salida de un comando.
- `$1` es el argumento. Antes de usarlo, revisar que exista con `[ -z ... ]` y `[ ! -d ... ]`.
- `$?` dice si el último comando salió bien. Con `>&2`, `logger` y `exit 1` el script avisa cuando algo falla.
- `bash -n` revisa la sintaxis y `bash -x` muestra cada paso.
- Los scripts del administrador van en `/usr/local/sbin`, de `root` y con modo 755.

## Enlaces útiles y referencias

- Ayuda en Debian: `man bash`, `help if`, `help for`, `man logger`.
- Clase 15: [presentación](https://linux.idepba.com.ar/clase15.html).
- Anterior: [Laboratorio 13.1 - Logs del sistema](../lab13/lab13.1.md).

-----

<p align="center">
<img src="../img/logos.footer.gray.webp">
</p>
