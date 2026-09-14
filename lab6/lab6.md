# Laboratorio 6 - Edición de archivos de texto en la terminal

## Objetivo

- Conocer la interfaz y los atajos principales de GNU nano.
- Buscar y editar texto en copias de archivos conocidos de Debian.
- Practicar los modos básicos de Vi/Vim.
- Guardar el trabajo o salir descartando los cambios.
- Recorrer un archivo con `more` cuando no disponemos de otro visor.
- Crear y transformar texto desde la shell.
- Revisar cada cambio con `diff`.

### Continuamos con la VM del Laboratorio 5

Vamos a usar la VM `Lab2`, con Debian 13, y nos conectaremos por SSH como en los laboratorios anteriores.

Todo el trabajo se hará dentro de `~/laboratorio-clase7`. Vamos a usar copias de archivos de Debian para no tocar los originales.

> [!NOTE]
> Reemplazá el nombre de usuario del comando SSH si utilizaste otro durante la instalación.

> [!IMPORTANT]
> No edites directamente los archivos de `/etc`. Primero vamos a copiarlos al home y trabajar con el usuario normal.

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

### 3. Comprobá qué herramientas están disponibles

```bash
nano --version
vi --version | head -n 2
tree --version | head -n 1
```

Las versiones pueden variar. Si falta alguna de las herramientas, instalala:

```bash
sudo apt update
sudo apt install nano vim tree
```

## 1. Preparar los archivos de trabajo

### 1. Volvé al home y creá el directorio del laboratorio

```bash
cd
mkdir -p ~/laboratorio-clase7
cd ~/laboratorio-clase7
pwd
```

> [!NOTE]
> Si `~/laboratorio-clase7` ya existe porque comenzaste antes la práctica, ingresá al directorio y revisá su contenido antes de continuar.

### 2. Copiá dos archivos conocidos de Debian

```bash
cp /etc/services servicios-nano.txt
cp /etc/hosts hosts-original
cp hosts-original hosts-nano
cp hosts-original hosts-vi
```

- `/etc/services` contiene nombres de servicios y puertos conocidos.
- `/etc/hosts` relaciona direcciones IP con nombres de equipos.
- Las copias `hosts-nano` y `hosts-vi` sirven para practicar ambos editores desde el mismo punto de partida.

### 3. Verificá los archivos antes de editarlos

```bash
ls -lh
file servicios-nano.txt hosts-original hosts-nano hosts-vi
diff -u hosts-original hosts-nano
diff -u hosts-original hosts-vi
```

Los dos últimos comandos no deberían mostrar diferencias.

### 4. Recorré un archivo sin abrir un editor

```bash
more servicios-nano.txt
```

Usá <kbd>Espacio</kbd> para avanzar una pantalla, <kbd>Enter</kbd> para avanzar una línea y <kbd>q</kbd> para salir.

`more` es más sencillo que `less`, pero puede resultar útil en sistemas mínimos donde no tenemos otro visor instalado.

## 2. Conocer la interfaz de Nano

### 1. Abrí la copia de `/etc/services`

```bash
nano servicios-nano.txt
```

Antes de escribir, mirá las partes de la pantalla:

- la barra superior muestra el nombre del programa y del archivo.
- el centro contiene el texto.
- la barra de estado muestra mensajes y preguntas.
- las últimas líneas recuerdan los atajos disponibles.

En los atajos de Nano, `^` representa `Ctrl` y `M-` representa `Alt` o Meta.

### 2. Buscá una palabra conocida

1. Presioná `Ctrl+F` o `Ctrl+W`.
2. Escribí `ssh`.
3. Presioná `Enter`.

Observá en qué columna aparece `ssh` y qué puerto tiene asociado.

Para practicar la búsqueda siguiente:

1. Iniciá otra búsqueda con `Ctrl+F` o `Ctrl+W` y escribí `http`.
2. Presioná `Alt+F` o `Alt+W` para recorrer sus distintas coincidencias.

### 3. Consultá la ubicación del cursor

```text
Ctrl+C
```

Nano muestra la línea, la columna y la posición actual. Después usá `Alt+G` para ir a una línea determinada y volvé a buscar `ssh` con `Ctrl+F` o `Ctrl+W`.

### 4. Salí sin realizar cambios

```text
Ctrl+X
```

Como no hicimos cambios, Nano debería cerrarse sin preguntar si queremos guardar.

## 3. Editar y guardar con Nano

### 1. Abrí la copia de `/etc/hosts`

```bash
nano hosts-nano
```

### 2. Buscá una línea existente

1. Presioná `Ctrl+F` o `Ctrl+W`.
2. Escribí `localhost`.
3. Presioná `Enter`.

Comprobá que el cursor queda ubicado sobre la coincidencia sin modificarla.

### 3. Agregá un nombre ficticio para el laboratorio

Ubicate al final del archivo y agregá:

```text
192.0.2.10 servidor-aula
```

La red `192.0.2.0/24` está reservada para documentación. Esta línea se usa solamente en la copia del laboratorio.

### 4. Practicá deshacer y rehacer

1. Escribí temporalmente otra línea.
2. Presioná `Alt+U` para deshacerla.
3. Presioná `Alt+E` para rehacerla.
4. Presioná nuevamente `Alt+U` para dejar solamente la línea `servidor-aula`.
5. Presioná `Backspace` una vez para quitar la línea vacía que quedó al final.

### 5. Guardá y salí

1. Presioná `Ctrl+O` para guardar.
2. Confirmá el nombre `hosts-nano` con `Enter`.
3. Presioná `Ctrl+X` para salir.

### 6. Verificá el resultado desde la shell

```bash
tail -n 5 hosts-nano
diff -u hosts-original hosts-nano
```

La comparación debería mostrar solamente la línea que agregaste.

## 4. Realizar una edición básica con Vi/Vim

No hace falta aprender todas las órdenes de Vi en esta práctica. Vamos a concentrarnos en abrir, buscar, editar, guardar y salir.

### 1. Abrí la copia preparada para Vi/Vim

```bash
vi hosts-vi
```

Vi/Vim comienza en modo normal. Si no sabés en qué modo estás, presioná `Esc` para volver a ese modo.

### 2. Buscá una palabra sin modificarla

En modo normal, escribí:

```vim
/localhost
```

Presioná `Enter`. Después presioná `n` para buscar la coincidencia siguiente, si existe.

### 3. Agregá una línea entrando en modo inserción

1. Presioná `G` para ir al final del archivo.
2. Presioná `o` para crear una línea debajo y entrar en modo inserción.
3. Escribí:

```text
192.0.2.20 servidor-respaldo
```

4. Presioná `Esc` para volver al modo normal.

La secuencia principal es:

```text
modo normal → o → modo inserción → Esc → modo normal
```

### 4. Guardá sin salir

En modo normal, escribí:

```vim
:w
```

Presioná `Enter`. El archivo queda guardado y el editor continúa abierto.

### 5. Salí normalmente

```vim
:q
```

Como ya guardamos los cambios, Vi/Vim debería cerrarse.

### 6. Verificá el resultado

```bash
tail -n 5 hosts-vi
diff -u hosts-original hosts-vi
```

La comparación debería mostrar la línea `servidor-respaldo`.

## 5. Salir de Vi/Vim descartando cambios

### 1. Abrí nuevamente el archivo

```bash
vi hosts-vi
```

### 2. Realizá un cambio que no quieras conservar

1. Presioná `G` y después `o`.
2. Escribí `esta-linea-se-descarta`.
3. Presioná `Esc`.

### 3. Intentá salir normalmente

```vim
:q
```

Vi/Vim debería advertir que existen cambios sin guardar y permanecer abierto.

### 4. Descartá el cambio y salí

```vim
:q!
```

El signo `!` fuerza la salida y descarta los cambios pendientes. No da permisos sobre el archivo.

### 5. Comprobá que la línea no fue guardada

```bash
grep -n 'esta-linea-se-descarta' hosts-vi
```

`grep` no debería mostrar ninguna coincidencia.

## 6. Crear un archivo sin abrir un editor

### 1. Creá una configuración ficticia con `echo`

```bash
echo 'nombre=servidor-aula' > servidor.conf
echo 'puerto=8080' >> servidor.conf
echo 'entorno=pruebas' >> servidor.conf
```

El operador `>` crea o reemplaza el archivo. El operador `>>` agrega contenido al final.

### 2. Verificá el resultado

```bash
cat -n servidor.conf
```

> [!CAUTION]
> Antes de usar `>` sobre un archivo existente, comprobá siempre el nombre de destino: su contenido anterior será reemplazado.

## 7. Transformar texto sin abrir un editor

### 1. Observá una sustitución con `sed`

```bash
sed 's/puerto=8080/puerto=9090/' servidor.conf
```

`sed` muestra el resultado transformado, pero deja intacto `servidor.conf`.

### 2. Guardá la transformación con otro nombre

```bash
sed 's/puerto=8080/puerto=9090/' servidor.conf > servidor-nuevo.conf
```

### 3. Compará antes de decidir

```bash
diff -u servidor.conf servidor-nuevo.conf
```

La comparación debería mostrar solamente el cambio del puerto.

> [!CAUTION]
> No redirijas la salida de `sed` al mismo archivo que estás leyendo. La shell puede vaciar el archivo antes de que `sed` alcance a procesarlo.

## 8. Verificación final

### 1. Revisá los archivos creados

```bash
tree ~/laboratorio-clase7
```

El resultado debería ser similar a:

```text
/home/cristian/laboratorio-clase7
├── hosts-nano
├── hosts-original
├── hosts-vi
├── servicios-nano.txt
├── servidor-nuevo.conf
└── servidor.conf

1 directory, 6 files
```

### 2. Compará los resultados de ambos editores

```bash
diff -u hosts-original hosts-nano
diff -u hosts-original hosts-vi
```

Cada comparación debería mostrar la línea agregada con el editor correspondiente.

### 3. Respondé antes de finalizar

1. ¿Qué información aparece en la parte inferior de Nano?
2. ¿Cómo se inicia una búsqueda en Nano?
3. ¿En qué modo comienza normalmente Vi/Vim?
4. ¿Qué tecla permite volver al modo normal?
5. ¿Qué diferencia existe entre `:w`, `:q` y `:q!`?
6. ¿Qué diferencia existe entre `>` y `>>`?
7. ¿Por qué guardamos la salida de `sed` con otro nombre?
8. ¿Cuándo usarías un editor y cuándo una transformación automática?

### 4. Conservá el entorno para revisarlo

No elimines todavía `~/laboratorio-clase7`. Vamos a usar estos archivos para revisar y comparar los resultados en clase.

## Resumen del laboratorio

- Nano muestra sus atajos y mensajes dentro de la propia interfaz.
- `more` permite recorrer un archivo pantalla por pantalla sin editarlo.
- `Ctrl+F` o `Ctrl+W` buscan, `Ctrl+O` guarda y `Ctrl+X` sale de Nano.
- Vi/Vim comienza normalmente en modo normal.
- `o` crea una línea y entra en modo inserción. `Esc` vuelve al modo normal.
- `/texto` inicia una búsqueda en Vi/Vim.
- `:w` guarda, `:q` sale y `:q!` descarta los cambios pendientes.
- `>` crea o reemplaza contenido y `>>` agrega al final.
- `sed` permite describir una transformación sin abrir un editor.
- `diff -u` permite verificar cada cambio antes de aceptarlo.

## Enlaces útiles y referencias

- [GNU nano](https://www.nano-editor.org/)
- [Manual de GNU nano](https://www.nano-editor.org/dist/latest/nano.html)
- [Documentación de Vim](https://vimhelp.org/)
- [GNU Bash - Redirections](https://www.gnu.org/software/bash/manual/html_node/Redirections.html)
- [GNU sed Manual](https://www.gnu.org/software/sed/manual/sed.html)
- [GNU Diffutils Manual](https://www.gnu.org/software/diffutils/manual/diffutils.html)
