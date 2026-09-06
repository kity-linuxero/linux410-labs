# Laboratorio 5 - Lectura, comparación y búsqueda de archivos

## Objetivo

- Seleccionar archivos mediante comodines y controlar la expansión con comillas.
- Identificar y consultar archivos de texto, binarios y comprimidos.
- Mostrar una parte del contenido y obtener conteos básicos.
- Comparar dos versiones de un archivo con `diff`.
- Buscar archivos con `find` y texto dentro de ellos con `grep`.
- Conectar comandos mediante tuberías sencillas.

### En este lab continuaremos con la VM utilizada en el Laboratorio 4

Vamos a utilizar la VM `Lab2`, con Debian 13, y nos conectaremos por SSH como en el laboratorio anterior.

Todo el trabajo se realizará dentro de `~/laboratorio-clase6`. Las operaciones con archivos se harán con el usuario normal.

> [!NOTE]
> Reemplazá el nombre de usuario del comando SSH si utilizaste otro durante la instalación.

## 0. Preparar la sesión

### 1. Iniciá la VM y conectate desde una terminal de la máquina anfitriona

```bash
ssh -p 2222 cristian@localhost
```

### 2. Confirmá el usuario, el equipo y el directorio actual

```bash
whoami
hostname
pwd
```

La salida de `pwd` debería mostrar el home de tu usuario, por ejemplo `/home/cristian`.

> [!IMPORTANT]
> Antes de trabajar con varios archivos, comprobá siempre el usuario, la ubicación y la ruta que recibirá el comando.

### 3. Verificá que `tree` esté instalado desde el laboratorio anterior

```bash
tree --version
```

Si el comando no está disponible, instalalo:

```bash
sudo apt update
sudo apt install tree
```

## 1. Preparar los archivos de trabajo

### 1. Volvé al home y creá el nuevo árbol de trabajo

```bash
cd
mkdir ~/laboratorio-clase6
cd ~/laboratorio-clase6
mkdir config datos logs
pwd
```

> [!NOTE]
> Si `~/laboratorio-clase6` ya existe porque comenzaste antes el ejercicio, no vuelvas a crearlo. Ingresá al directorio y revisá su contenido con `tree` antes de continuar.

### 2. Copiá archivos reales del sistema para trabajar sin modificar los originales

```bash
cp /usr/lib/os-release config/sistema.conf
cp /etc/hosts config/hosts.conf
cp /etc/services datos/servicios.txt
cp /etc/passwd datos/usuarios.txt
```

### 3. Prepará nombres que permitan practicar los comodines

```bash
cp /etc/hostname datos/archivo-hostname-0
cp /etc/hosts datos/archivo-hosts-1
cp /usr/lib/os-release datos/archivo-sistema-2
cp /etc/services datos/archivo-servicios-4

cp /etc/hosts logs/acceso-01.log
cp /etc/hostname logs/acceso-02.log
cp /usr/lib/os-release logs/error-01.log

touch datos/.nota-oculta
```

### 4. Observá el resultado antes de seguir

```bash
tree -a ~/laboratorio-clase6
```

La opción `-a` permite ver también `.nota-oculta`.
El resultado debería ser como el siguiente:

```bash
/home/cristian/laboratorio-clase6
├── config
│   ├── hosts.conf
│   └── sistema.conf
├── datos
│   ├── archivo-hostname-0
│   ├── archivo-hosts-1
│   ├── archivo-servicios-4
│   ├── archivo-sistema-2
│   ├── .nota-oculta
│   ├── servicios.txt
│   └── usuarios.txt
└── logs
    ├── acceso-01.log
    ├── acceso-02.log
    └── error-01.log

4 directories, 12 files

```

## 2. Seleccionar nombres con comodines

### 1. Listá todos los archivos terminados en `.txt` dentro de `datos`

```bash
ls datos/*.txt
```
El resultado debería ser el siguiente:
```bash
cristian@lab2-vm:~/laboratorio-clase6$ ls datos/*.txt
datos/servicios.txt  datos/usuarios.txt

cristian@lab2-vm:~/laboratorio-clase6$ ls datos/
archivo-hostname-0  archivo-hosts-1  archivo-servicios-4  archivo-sistema-2  servicios.txt  usuarios.txt
```
Como se puede observar, el comodín funcionó según lo esperado. Si el resultado es distinto verificar la sintaxis.


### 2. Seleccioná los logs cuyo nombre comienza con `acceso-0` y tiene un carácter antes de `.log`

```bash
ls logs/acceso-0?.log
```

Deberían aparecer `acceso-01.log` y `acceso-02.log`.

### 3. Combiná `*` con el rango `[0-3]`

```bash
ls datos/archivo*[0-3]
```

El patrón selecciona los nombres que comienzan con `archivo` y terminan con un dígito entre `0` y `3`. `archivo-servicios-4` debe quedar afuera.

### 4. Compará el patrón anterior con el mismo texto entre comillas

```bash
ls 'datos/archivo*[0-3]'
```

Ahora Bash no expande los comodines. `ls` intenta encontrar un archivo que contiene literalmente `*` y `[0-3]` en su nombre, por eso informa que no existe. Por eso, el resultado esperado es `No existe el fichero o el directorio`.

### 5. Comprobá la diferencia entre un listado normal y uno que incluye nombres ocultos

```bash
ls datos/*
ls -la datos
```
Debería poder visualizar `.nota-oculta`, además de `.` y `. .` que hacen referencia al directorio actual y al directorio padre respectivamente.

## 3. Identificar y leer archivos

### 1. Identificá un archivo de texto y un ejecutable

```bash
file datos/servicios.txt
file /bin/ls
```

Las descripciones exactas pueden variar. Lo importante es distinguir el archivo de texto del archivo binario ejecutable. En la sección siguiente también identificaremos la copia comprimida.

> [!CAUTION]
> No utilices `cat` sobre `/bin/ls`. Los archivos binarios pueden producir una salida ilegible y caracteres de control en la terminal.

### 2. Mostrá un archivo breve con `cat`

```bash
cat /etc/hostname
cat -n config/sistema.conf
```
La opción `-n` nos mostrará el número de línea seguido del contenido del archivo enviado por parámetro.

### 3. Abrí un archivo más extenso con `less`

```bash
less datos/servicios.txt
```

Dentro de `less`:

- utilizá las flechas para avanzar y retroceder;
- buscá `ftp` escribiendo `/ftp` y presionando `Enter`. El resultado aparecerá arriba en la pantalla.
- presioná `n` para buscar la siguiente coincidencia;
- presioná `q` para salir.

### 4. Abrí el mismo archivo con `more` y compará la navegación

```bash
more datos/servicios.txt
```

Salí con `q`. `more` cumple la misma función básica, pero ofrece menos posibilidades para desplazarse y buscar.

## 4. Comprimir y consultar un archivo `.gz`

### 1. Creá una copia comprimida sin eliminar el archivo original

```bash
gzip -k datos/servicios.txt
```

### 2. Compará los tamaños e identificá ambos archivos

```bash
ls -lh datos/servicios.txt datos/servicios.txt.gz
file datos/servicios.txt datos/servicios.txt.gz
```

Detenete un momento y comprobá:

- ¿siguen existiendo los dos archivos?
- ¿cuál ocupa menos espacio?
- ¿qué tipo informa `file` para cada uno?

### 3. Mostrá solamente las primeras cinco líneas de la copia comprimida

```bash
zcat datos/servicios.txt.gz | head -n 5
```

`zcat` entrega el contenido descomprimido y `head` conserva las primeras cinco líneas.

### 4. Recorré el archivo con el visor paginado y salí con `q`

```bash
zless datos/servicios.txt.gz
```

El archivo continúa comprimido después de cerrar `zless`.

## 5. Observar una parte y contar

### 1. Mostrá el principio y el final de distintos archivos

```bash
head -n 5 datos/usuarios.txt
tail -n 5 datos/usuarios.txt
tail -n 10 /var/log/dpkg.log
```

### 2. Observá en tiempo real cómo se agregan líneas a un archivo

Para que `tail -f` tenga algo nuevo que mostrar, vas a trabajar con dos terminales conectadas a la VM.

#### Terminal 1: seguí el archivo

Creá un archivo vacío y dejá `tail -f` ejecutándose:

```bash
cd ~/laboratorio-clase6
touch logs/actividad.log
tail -f logs/actividad.log
```

El comando queda esperando porque muestra las líneas nuevas a medida que se incorporan al archivo.

#### Terminal 2: agregá contenido

Sin cerrar la primera terminal, abrí otra, conectate nuevamente por SSH y ejecutá:

Conexión por ssh:
```bash
ssh -p 2222 cristian@localhost

```bash
echo "Inicio de una tarea" >> ~/laboratorio-clase6/logs/actividad.log
echo "Tarea en ejecución" >> ~/laboratorio-clase6/logs/actividad.log
echo "Tarea finalizada" >> ~/laboratorio-clase6/logs/actividad.log
```

Volvé a la primera terminal después de cada comando y observá cómo aparece la línea nueva. El operador `>>` agrega contenido al final sin reemplazar lo que ya existía.

Cuando termines, interrumpí `tail -f` con `Ctrl + C`.

Podés cerrar la segunda terminal con el comando `exit` dos veces, una para salir de la sesión ssh al server y el segundo exit para cerrar la terminal de tu computadora; seguiremos trabajando con la terminal 1.

### 3. Obtené distintos conteos

```bash
wc datos/usuarios.txt
wc -l datos/usuarios.txt
wc -w datos/servicios.txt
wc -c config/hosts.conf
```
El resultado esperado debería ser:
```bash
  24   35 1237 datos/usuarios.txt
  24 datos/usuarios.txt
1795 datos/servicios.txt
187 config/hosts.conf
```

Sin opciones, `wc` muestra líneas, palabras y bytes, en ese orden.

> [!NOTE]
> `wc` viene de *word count*. El nombre ayuda a recordarlo, aunque también cuenta líneas, bytes y caracteres.

## 6. Comparar dos versiones con `diff`

Para observar una diferencia necesitamos preparar dos archivos parecidos. Vamos a recuperar `tee`, que recibe la salida del comando anterior y la envía al mismo tiempo a la terminal y al archivo indicado.

### 1. Creá una versión corta y otra con dos líneas adicionales

```bash
head -n 3 datos/usuarios.txt | tee config/usuarios-anterior.txt
head -n 5 datos/usuarios.txt | tee config/usuarios-actual.txt
```

En cada tubería, `head` produce las líneas y `tee` las muestra mientras crea el archivo. Sin la opción `-a`, si el archivo ya existe, reemplaza su contenido.

### 2. Compará una versión con una copia idéntica

```bash
cp config/usuarios-anterior.txt config/usuarios-copia.txt
diff config/usuarios-anterior.txt config/usuarios-copia.txt
```

`diff` no muestra nada porque los archivos tienen el mismo contenido.

### 3. Compará ahora las dos versiones diferentes

```bash
diff -u config/usuarios-anterior.txt config/usuarios-actual.txt
```

Leé la salida antes de continuar:

- `---` identifica el primer archivo;
- `+++` identifica el segundo;
- las líneas con `+` aparecen en la segunda versión;
- las líneas sin signo aportan contexto.

### 4. Repetí la comparación con color

```bash
diff --color -u config/usuarios-anterior.txt config/usuarios-actual.txt
```

El color facilita la lectura en la terminal. Los signos `-` y `+` conservan el significado.

## 7. Buscar archivos con `find`

### 1. Asegurate de estar en el directorio principal del laboratorio

```bash
cd ~/laboratorio-clase6
pwd
```

### 2. Buscá archivos y directorios dentro del árbol

```bash
find . -type f
find . -type d
```

El punto indica que el recorrido comienza en el directorio actual.

### 3. Buscá solamente archivos terminados en `.log`

```bash
find . -type f -name '*.log'
```

Las comillas hacen que el patrón llegue sin modificar a `find`.

### 4. Probá otros criterios para reducir los resultados

```bash
find . -maxdepth 2 -type f -iname '*sistema*'
find . -type f -size +1k
find . -type f -mtime -1
```

Detenete y observá qué cambia en cada búsqueda:

- `-maxdepth 2` limita la profundidad;
- `-iname` ignora mayúsculas y minúsculas;
- `-size +1k` busca archivos mayores que 1 KiB;
- `-mtime -1` busca archivos modificados durante las últimas 24 horas.

## 8. Buscar texto con `grep`

### 1. Buscá texto y agregá el número de línea

```bash
grep -n 'root' datos/usuarios.txt
```

### 2. Realizá una búsqueda que ignore mayúsculas y minúsculas

```bash
grep -in 'ssh' datos/servicios.txt
```

### 3. Exigí una palabra completa

```bash
grep -w 'root' datos/usuarios.txt
```

Hasta aquí `grep` abrió directamente un archivo. Ahora vamos a ampliar y después limitar el alcance de la búsqueda.

### 4. Buscá `localhost` de forma recursiva dentro de `config` y `logs`

```bash
grep -r -n 'localhost' config logs
```

### 5. Repetí la búsqueda, pero solamente sobre archivos terminados en `.conf`

```bash
grep -r -n --include='*.conf' 'localhost' config logs
```

Compará ambas salidas. La segunda búsqueda debe excluir los archivos `.log`.

> [!IMPORTANT]
> Una búsqueda recursiva puede recorrer mucho más de lo esperado. Elegí primero los directorios de inicio y luego aplicá filtros sobre los nombres.

## 9. Conectar comandos con tuberías

### 1. Compará estas dos formas de buscar la palabra `ssh`

```bash
cat datos/servicios.txt | grep -w 'ssh'
grep -w 'ssh' datos/servicios.txt
```

Los dos comandos encuentran las mismas líneas. En el primero, `cat` no aporta una función necesaria porque `grep` puede abrir el archivo directamente.

### 2. Utilizá una tubería con una función concreta

```bash
grep -in 'tcp' datos/servicios.txt | head -n 5
```

`grep` produce las coincidencias y `head` conserva solamente las cinco primeras.

### 3. Contá cuántos archivos existen dentro del laboratorio

```bash
find . -type f | wc -l
```

La salida de `find` se convierte en la entrada de `wc -l`. No hace falta guardar una lista intermedia. El resultado esperado es `17`.

## 10. Verificación final

### 1. Revisá el árbol completo

```bash
tree -a ~/laboratorio-clase6
```

### 2. Comprobá que todavía existen el archivo original y su copia comprimida

```bash
ls -lh datos/servicios.txt datos/servicios.txt.gz
```

### 3. Respondé antes de finalizar

- ¿Por qué `archivo-servicios-4` no apareció con el patrón `archivo*[0-3]`?
- ¿Qué cambió al escribir el patrón entre comillas?
- ¿Qué diferencia observaste entre `less` y `more`?
- ¿Qué representan las líneas con `+` en la salida de `diff -u`?
- ¿Cuándo utilizarías `find` y cuándo utilizarías `grep`?
- ¿Por qué la tubería `cat archivo | grep texto` puede resultar redundante?

## 11. Dejar el entorno preparado

No borres `~/laboratorio-clase6` al terminar. Los archivos `usuarios-anterior.txt`, `usuarios-actual.txt`, `hosts.conf` y `sistema.conf` servirán para practicar con editores de texto en próximos labs.

Antes de cerrar la sesión, volvé al home:

```bash
cd
pwd
```

Salí de SSH con:

```bash
exit
```

## Resumen de Lab

En este laboratorio seleccionamos nombres con comodines, identificamos distintos tipos de archivo y elegimos cómo consultarlos. Creamos una copia comprimida, observamos partes del contenido y realizamos conteos. También comparamos dos versiones, buscamos archivos por sus propiedades, buscamos texto y conectamos comandos mediante tuberías. El entorno queda preparado para continuar en la próxima clase.

## Links útiles y referencias

- [Apuntes teóricos de la Clase 6](https://linux.idepba.com.ar/clase6.html)
- [Laboratorio 4 - Navegación y operaciones con archivos](../lab4/lab4.md)
- [GNU Bash Reference Manual](https://www.gnu.org/software/bash/manual/bash.html)
- [GNU Coreutils Manual](https://www.gnu.org/software/coreutils/manual/coreutils.html)
- [GNU Diffutils Manual](https://www.gnu.org/software/diffutils/manual/diffutils.html)
- [GNU Findutils Manual](https://www.gnu.org/software/findutils/manual/html_mono/find.html)
- [GNU Grep Manual](https://www.gnu.org/software/grep/manual/grep.html)
- [Debian Manpages](https://manpages.debian.org/)

-----

<p align="center">
<img src="../img/logos.footer.gray.webp">
</p>
