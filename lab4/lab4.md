# Laboratorio 4 - Navegación y operaciones con archivos

## Objetivo

- Trabajar desde una sesión SSH utilizando Bash.
- Navegar por el sistema con rutas absolutas y relativas.
- Crear una estructura de directorios y archivos dentro del home del usuario.
- Copiar, mover, renombrar y eliminar objetos de forma controlada.
- Utilizar Tab, el historial y `Ctrl + R` para trabajar con mayor precisión.
- Provocar errores comunes, leer sus mensajes y corregir la causa sin recurrir a `sudo`.

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

```bash
cristian
lab2-vm
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

**1. Nos aseguramos de estar en nuestro `home`:**

```bash
cd
```

**2. Creamos el directorio principal e ingresamos:**

```bash
mkdir ~/laboratorio-clase5
cd ~/laboratorio-clase5
pwd
```

**3. Creamos varios directorios con una misma orden:**

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
**4. Intentamos crear un directorio cuyo padre todavía no existe:**

```bash
mkdir datos/clientes/norte
```

El comando debe fallar porque falta `datos/clientes`. Leemos el mensaje completo y corregimos la causa con `-p`:

```bash
mkdir -p datos/clientes/norte
mkdir -p datos/clientes/sur
mkdir -p backup/diario
```

**5. Creamos un directorio con espacios en el nombre:**

```bash
mkdir "Documentos del curso"
```

Las comillas hacen que Bash interprete el nombre completo como un único argumento.

**6. Revisamos el resultado:**

```bash
ls -la # Listaremos todos los archivos
```

```bash
tree ~/laboratorio-clase5 # Listaremos el árbol de directorios
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
ls -la .
```
Practicamos con `<tab>`:

```bash
ls -la /home/<tab>/la<tab>
# Seguir con tab hasta que liste laboratorio-clase5
```

En el primer comando:

- `ls` es el comando.
- `-la` reúne dos opciones. (`--long` y `--all`).
- `/home/cristian/laboratorio-clase5` es el argumento y una ruta absoluta.

En el primer comando, `.` representa el directorio actual y es una ruta relativa. Ambos listados deberían mostrar el mismo contenido.



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
```
- Listaremos el directorio

```bash
ls
```

- Listaremos TODOS los archivos/directorios.

```bash
ls -la
```

Con ese último comando deberíamos visualizar `.inventario`. Los nombres que comienzan con `.` no aparecen en un listado normal, pero sí con la opción `-a`.

**4. Volvemos a ejecutar `touch` sobre un archivo que ya existe:**

```bash
ls -l config/servidor.conf
touch config/servidor.conf
ls -l config/servidor.conf
```

El archivo sigue vacío. `touch` actualiza sus marcas de tiempo; no es un editor y no borra el contenido de un archivo existente.

## 4. Copiar archivos y directorios

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
```

## 5. Mover y renombrar

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

Verificar con `tree`:

```bash
tree ~/laboratorio-clase5/
```

Debería ser esta salida:

```bash
/home/cristian/laboratorio-clase5/
├── backup
│   ├── diario
│   │   ├── acceso.log
│   │   └── error.log
│   └── servidor.conf
├── config
│   └── servidor.conf
├── datos
│   ├── clientes
│   │   └── sur
│   │       └── clientes.txt
│   ├── cliente.txt
│   ├── Cliente.txt
│   └── norte
│       └── clientes.txt
├── Documentos del curso
└── logs
    └── acceso-anterior.log

10 directories, 9 files

```

## 6. Usar el historial

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

## 7. Provocar y diagnosticar errores

Los siguientes errores son intencionales. 

### 7.1 Ruta inexistente

```bash
ls datos/oeste
```

El mensaje `No such file or directory` o `No existe el fichero o el directorio indica que la ruta no existe. Comprobamos los nombres disponibles:

```bash
pwd
ls -la datos
```

### 7.2 Un archivo no es un directorio

```bash
cd config/servidor.conf
```

`servidor.conf` existe, pero no es un directorio. Lo comprobamos con:

```bash
ls -l config/servidor.conf
```

### 7.3 Directorio no vacío

```bash
rmdir logs
```

`rmdir` solo elimina directorios vacíos. Revisamos su contenido:

```bash
ls -la logs
```

### 7.4 Falta un argumento

```bash
cp config/servidor.conf
```

`cp` necesita un origen y un destino. Consultamos la sintaxis antes de corregirlo:

```bash
cp --help
```


## 8. Verificación final

**1. Confirmamos usuario, ubicación y contenido antes de borrar:**

```bash
whoami
pwd
ls -la
ls -la config logs datos backup
tree -a ~/laboratorio-clase5
```

La opción `-a` incluye también los nombres ocultos, como `.inventario`.

**2. Verificamos que los archivos importantes estén en la ubicación esperada:**

```bash
ls -l config/servidor.conf
ls -l backup/servidor.conf
ls -l logs/acceso-anterior.log
ls -l backup/diario/error.log
```

**3. Respondemos estas preguntas antes de continuar:**

- Mencioná una ruta absoluta y una ruta relativa utilizadas durante el laboratorio.
- ¿Por qué `cliente.txt` y `Cliente.txt` pueden coexistir?
- ¿Qué diferencia hubo entre copiar y mover `error.log`?
- ¿Por qué `rmdir logs` produjo un error?

## 9. Limpieza segura

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

En este laboratorio trabajamos por SSH dentro de un árbol aislado en el home del usuario. Navegamos con rutas absolutas y relativas, usamos Tab y el historial, creamos directorios y archivos, comprobamos que Linux distingue mayúsculas de minúsculas y practicamos con nombres ocultos y nombres con espacios. También copiamos, movimos, renombramos y eliminamos objetos después de verificar su ubicación. Finalmente provocamos errores frecuentes, leímos sus mensajes y corregimos la causa sin agregar privilegios innecesarios.

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
