# Laboratorio 4 - Navegación y operaciones con archivos

## Objetivo

- Trabajar desde una sesión SSH utilizando Bash.
- Navegar por el sistema con rutas absolutas y relativas.
- Crear una estructura de directorios y archivos dentro del home del usuario.
- Copiar, mover, renombrar y eliminar objetos de forma controlada.
- Utilizar Tab, el historial y `Ctrl + R` para trabajar con mayor precisión.
- Provocar errores comunes, leer sus mensajes y corregir la causa sin recurrir a `sudo`.
- Escribir y revisar contenido sencillo mediante `echo` y `cat`.

### En este lab continuaremos con la VM del Laboratorio 3

Vamos a utilizar la VM `Lab2`, con Debian 13.

> [!NOTE]
> Reemplazá los nombres de usuario en los comandos cuando corresponda.

Todo el trabajo se realizará dentro de `~/laboratorio-clase5`. Solo utilizaremos `sudo` para instalar las herramientas del laboratorio; las operaciones con archivos se harán con el usuario normal.

## 0. Preparar la sesión

**1. Iniciamos la VM.**

**2. En la máquina anfitriona abrimos una terminal y nos conectamos por SSH:**

```bash
ssh -p 2222 cristian@localhost
```

**3. Antes de comenzar, comprobamos el usuario, el equipo y el directorio actual:**

```bash
whoami
hostname
pwd
```

La salida de `pwd` debería mostrar el home del usuario, por ejemplo:

```text
/home/cristian
```

> [!IMPORTANT]
> Antes de ejecutar un comando sobre archivos conviene confirmar tres cosas: con qué usuario estamos trabajando, en qué directorio estamos y qué ruta recibirá el comando.

**4. Instalamos `tree`:**

```bash
sudo apt update
sudo apt install tree
```

`tree` muestra el contenido de un directorio con forma de árbol. Nos va a ayudar a visualizar cómo se relacionan los directorios y archivos que iremos creando durante el laboratorio.

Comprobamos que quedó instalado:

```bash
tree --version
```

## 1. Crear el entorno de trabajo

**1. Regresamos al home y verificamos dónde estamos:**

```bash
cd
pwd
```

**2. Antes de crear el laboratorio, comprobamos si ya existe:**

```bash
ls -ld ~/laboratorio-clase5
```

Si aparece `No such file or directory` o `No existe el fichero o el directorio`, podemos continuar. Si el directorio ya existe por una práctica anterior, lo borraremos para empezar de cero.

> [!CAUTION]
> Antes de ejecutar el siguiente comando, comprobá que la ruta sea exactamente `~/laboratorio-clase5`. `rm -rf` elimina todo el árbol sin pedir confirmación y no utiliza una papelera.

```bash
rm -rf ~/laboratorio-clase5
```

**3. Creamos el directorio principal e ingresamos:**

```bash
mkdir ~/laboratorio-clase5
cd ~/laboratorio-clase5
pwd
```

**4. Creamos varios directorios con una misma orden:**

```bash
mkdir config logs datos backup
```
Verificamos el árbol de directorios con `tree` seguido de un `.`

```bash
cristian@lab2-vm:~/laboratorio-clase5$ tree .
.
├── backup
├── config
├── datos
└── logs

5 directories, 0 files
```
**5. Intentamos crear un directorio cuyo padre todavía no existe:**

```bash
mkdir datos/clientes/norte
```

El comando debe fallar porque falta `datos/clientes`. Leemos el mensaje completo y corregimos la causa con `-p`:

```bash
mkdir -p datos/clientes/norte
mkdir -p datos/clientes/sur
mkdir -p backup/diario
```

**6. Creamos un directorio con espacios en el nombre:**

```bash
mkdir "Documentos del curso"
```

Las comillas hacen que Bash interprete el nombre completo como un único argumento.

**7. Revisamos el resultado:**

```bash
ls -la
ls -ld config logs datos backup "Documentos del curso"
tree ~/laboratorio-clase5
```

La salida de `tree` permite observar la estructura completa de un vistazo, desde el directorio principal hasta los últimos subdirectorios:

```text
$ tree ~/laboratorio-clase5
/home/cristian/laboratorio-clase5
├── backup
│   └── diario
├── config
├── datos
│   └── clientes
│       ├── norte
│       └── sur
├── Documentos del curso
└── logs

10 directories, 0 files
```

## 2. Practicar navegación y autocompletado

**1. Comparamos una ruta absoluta con una relativa mientras estamos en el directorio principal del laboratorio:**

```bash
ls -la /home/cristian/laboratorio-clase5
ls -la .
```

En el primer comando:

- `ls` es el comando.
- `-la` reúne dos opciones.
- `/home/cristian/laboratorio-clase5` es el argumento y una ruta absoluta.

En el segundo, `.` representa el directorio actual y es una ruta relativa. Ambos listados deberían mostrar el mismo contenido.

> [!NOTE]
> Si tu usuario no es `cristian`, reemplazá ese componente de la ruta absoluta por tu nombre de usuario.

**2. Entramos en un directorio utilizando una ruta relativa:**

```bash
cd datos/clientes/norte
pwd
```

**3. Subimos dos niveles y comprobamos la ubicación:**

```bash
cd ../..
pwd
```

Ahora deberíamos estar en `~/laboratorio-clase5/datos`.

**4. Volvemos al directorio anterior y luego regresamos al laboratorio:**

```bash
cd -
cd ~/laboratorio-clase5
```

**5. Practicamos el autocompletado. Escribimos lo siguiente sin presionar `Enter`:**

```text
cd Doc
```

Presionamos `Tab`. Bash debería completar el nombre del directorio y proteger el espacio con una barra invertida:

```text
cd Documentos\ del\ curso/
```

Presionamos `Enter`, comprobamos la ruta y volvemos:

```bash
pwd
cd ..
```

> [!TIP]
> Tab completa el nombre real y reduce errores de tipeo, pero no decide si la operación que estamos por ejecutar es correcta.

## 3. Crear archivos y distinguir nombres

**1. Creamos varios archivos vacíos:**

```bash
touch config/servidor.conf
touch logs/acceso.log logs/error.log
touch datos/clientes/norte/clientes.txt
touch datos/clientes/sur/clientes.txt
```

**2. Comprobamos que Linux distingue mayúsculas de minúsculas:**

```bash
touch datos/cliente.txt datos/Cliente.txt
ls -l datos
```

`cliente.txt` y `Cliente.txt` son dos archivos diferentes.

**3. Creamos un archivo oculto y comparamos los listados:**

```bash
touch .inventario
ls
ls -a
```

Los nombres que comienzan con `.` no aparecen en un listado normal, pero sí con la opción `-a`.

**4. Volvemos a ejecutar `touch` sobre un archivo que ya existe:**

```bash
ls -l config/servidor.conf
touch config/servidor.conf
ls -l config/servidor.conf
```

El archivo sigue vacío. `touch` actualiza sus marcas de tiempo; no es un editor y no borra el contenido de un archivo existente.

## 4. Ampliación: escribir contenido y mostrarlo

Hasta ahora utilizamos `touch` para crear archivos vacíos. Para que las copias del laboratorio tengan contenido, vamos a incorporar `echo` y `cat`:

- `echo` muestra un texto en la salida estándar, normalmente la terminal.
- `cat` muestra el contenido de uno o más archivos.

Para guardar la salida de `echo` utilizaremos `>` y `>>`. Estos símbolos son **redirecciones de Bash**: por ahora solamente los usaremos para completar la práctica; su funcionamiento se explicará más adelante en otra clase teórica.

**1. Escribimos dos líneas en la configuración:**

```bash
echo "servidor=lab2-vm" > config/servidor.conf
echo "entorno=practica" >> config/servidor.conf
```

**2. Agregamos contenido a los logs:**

```bash
echo "inicio correcto" > logs/acceso.log
echo "prueba de error" > logs/error.log
```

**3. Verificamos el resultado:**

```bash
cat config/servidor.conf
cat logs/acceso.log logs/error.log
```

> [!NOTE]
> En esta práctica, `>` guarda la salida reemplazando el contenido anterior y `>>` agrega la salida al final. Las redirecciones se desarrollarán con más detalle en una clase posterior.

## 5. Copiar archivos y directorios

Nos aseguramos de estar en el directorio principal del laboratorio:

```bash
cd ~/laboratorio-clase5
pwd
```

**1. Copiamos la configuración con un nombre nuevo:**

```bash
cp config/servidor.conf backup/servidor.conf
```

**2. Copiamos dos archivos al directorio de backup diario:**

```bash
cp logs/acceso.log logs/error.log backup/diario/
```

**3. Copiamos un directorio completo:**

```bash
cp -r config backup/config-copia
```

**4. Intentamos copiar nuevamente la configuración usando las opciones `-i` y `-v`:**

```bash
cp -iv config/servidor.conf backup/servidor.conf
```

- `-i` pregunta antes de sobrescribir.
- `-v` muestra la operación.

Respondemos `n` para conservar la copia existente.

**5. Comprobamos origen y destino:**

```bash
ls -l config
ls -l backup backup/diario backup/config-copia
cat backup/servidor.conf
```

## 6. Mover y renombrar

**1. Renombramos el log de acceso:**

```bash
mv logs/acceso.log logs/acceso-anterior.log
```

**2. Movemos el log de error al backup diario:**

```bash
mv logs/error.log backup/diario/
```

**3. Movemos el directorio `norte` un nivel hacia arriba:**

```bash
mv datos/clientes/norte datos/
```

**4. Verificamos siempre el origen y el destino:**

```bash
ls -la logs
ls -la backup/diario
ls -la datos
ls -la datos/clientes
```

Al finalizar:

- `logs` debe contener `acceso-anterior.log`.
- `backup/diario` debe contener `acceso.log` y `error.log`.
- `datos/norte` debe existir.
- `datos/clientes` debe conservar el directorio `sur`.

## 7. Usar el historial

**1. Mostramos las órdenes recientes:**

```bash
history
```

**2. Presionamos `Ctrl + R`, escribimos una parte de una orden anterior, por ejemplo:**

```text
backup/diario
```

**3. Cuando aparezca una coincidencia:**

- Presionamos nuevamente `Ctrl + R` para buscar otra.
- Usamos una flecha para dejar la orden en la línea y editarla.
- Leemos la orden completa antes de ejecutarla.
- Presionamos `Ctrl + C` si queremos cancelar la búsqueda.

**4. Limpiamos solamente la pantalla con:**

```bash
clear
```

También podemos usar `Ctrl + L`. Después ejecutamos `history` otra vez para comprobar que limpiar la pantalla no borra el historial.

## 8. Provocar y diagnosticar errores

Los siguientes errores son intencionales. No agregamos `sudo`: primero leemos el mensaje y revisamos la ruta.

### 8.1 Ruta inexistente

```bash
ls datos/oeste
```

El mensaje `No such file or directory` indica que la ruta no existe. Comprobamos los nombres disponibles:

```bash
pwd
ls -la datos
```

### 8.2 Un archivo no es un directorio

```bash
cd config/servidor.conf
```

`servidor.conf` existe, pero no es un directorio. Lo comprobamos con:

```bash
ls -l config/servidor.conf
```

### 8.3 Directorio no vacío

```bash
rmdir logs
```

`rmdir` solo elimina directorios vacíos. Revisamos su contenido:

```bash
ls -la logs
```

### 8.4 Falta un argumento

```bash
cp config/servidor.conf
```

`cp` necesita un origen y un destino. Consultamos la sintaxis antes de corregirlo:

```bash
cp --help
```


## 9. Verificación final

**1. Confirmamos usuario, ubicación y contenido antes de borrar:**

```bash
whoami
pwd
ls -la
ls -la config logs datos backup
tree -a ~/laboratorio-clase5
```

La opción `-a` incluye también los nombres ocultos, como `.inventario`.

**2. Verificamos archivos importantes:**

```bash
cat config/servidor.conf
cat backup/servidor.conf
cat logs/acceso-anterior.log
cat backup/diario/error.log
```

**3. Respondemos estas preguntas antes de continuar:**

- Mencioná una ruta absoluta y una ruta relativa utilizadas durante el laboratorio.
- ¿Por qué `cliente.txt` y `Cliente.txt` pueden coexistir?
- ¿Qué diferencia hubo entre copiar y mover `error.log`?
- ¿Por qué `rmdir logs` produjo un error?
- ¿Para qué utilizamos `echo` y `cat`?

## 10. Limpieza segura

El objetivo es eliminar únicamente el árbol creado para este laboratorio.

**1. Volvemos al home. No intentamos borrar un directorio mientras estamos ubicados dentro de él:**

```bash
cd
pwd
```

**2. Confirmamos el objetivo:**

```bash
ls -ld ~/laboratorio-clase5
ls -la ~/laboratorio-clase5
```

**3. Eliminamos el árbol en modo interactivo:**

```bash
rm -ri ~/laboratorio-clase5
```

Leemos cada pregunta antes de responder. Al finalizar, verificamos que ya no exista:

```bash
ls -ld ~/laboratorio-clase5
```

El mensaje `No such file or directory` confirma que el objetivo fue eliminado.

> [!CAUTION]
> No eliminamos otros directorios del home. Antes de confirmar cada borrado, verificá que todos los elementos pertenezcan a `~/laboratorio-clase5`.

### Limpieza opcional del historial

La limpieza del historial no es necesaria para completar este laboratorio. Si estamos preparando una VM para convertirla en plantilla y no hay otras sesiones abiertas con el mismo usuario, podemos ejecutar:

```bash
history -c
history -w
```

`history -c` limpia la lista de la sesión actual y `history -w` sobrescribe `~/.bash_history` con esa lista. Esto no elimina logs del sistema ni reemplaza otras tareas de preparación de una plantilla.

## Resumen de Lab

En este laboratorio trabajamos por SSH dentro de un árbol aislado en el home del usuario. Navegamos con rutas absolutas y relativas, usamos Tab y el historial, creamos directorios y archivos, comprobamos que Linux distingue mayúsculas de minúsculas y practicamos con nombres ocultos y nombres con espacios. También copiamos, movimos, renombramos y eliminamos objetos después de verificar su ubicación.

Además, incorporamos dos herramientas sencillas: usamos `echo` para generar texto y `cat` para revisar el contenido de los archivos. Para guardar ese texto usamos de manera introductoria las redirecciones `>` y `>>`, que se explicarán con más detalle en otra clase. Finalmente provocamos errores frecuentes, leímos sus mensajes y corregimos la causa sin agregar privilegios innecesarios.

## Links útiles y referencias

- [Apuntes teóricos del curso](https://linux.idepba.com.ar/clase5.html)
- [Laboratorio 3 - Post-instalación y primer acceso por SSH](../lab3/lab3.md)
- [GNU Bash Reference Manual](https://www.gnu.org/software/bash/manual/bash.html)
- [GNU Coreutils Manual](https://www.gnu.org/software/coreutils/manual/coreutils.html)
- [Debian Manpages](https://manpages.debian.org/)

-----

<p align="center">
<img src="../img/logos.footer.gray.webp">
</p>
