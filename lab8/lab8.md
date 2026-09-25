# Laboratorio 8 - Permisos y directorios compartidos

> Borrador para revisión docente. Acompaña la clase 9. Recorrido de permisos probado el 2026-09-25 en Debian 13.6 con cuentas existentes y sesiones mediante `su`. La preparación con cuentas ausentes sigue pendiente de prueba.

## Objetivo

- Cambiar owner, grupo y permisos con `chown`, `chgrp` y `chmod`.
- Diagnosticar un rechazo de acceso revisando el archivo y su ruta.
- Usar SGID y umask para crear archivos que puedan editar los integrantes de un equipo.
- Comprobar la diferencia entre editar un archivo y borrarlo.

### Punto de partida

Usamos la VM Debian 13 del curso y una cuenta administradora con `sudo`, por ejemplo `cristian`. **No necesitás haber hecho el Laboratorio 7.** La preparación inicial permite crear las cuentas que falten. Si ya hiciste ese laboratorio, vas a reutilizarlas y conservar sus archivos.

El resultado será un directorio `/srv/equipo` con acceso grupal para Ana y Bruno. Comprobarán la edición compartida y la diferencia entre editar y borrar. Reservá tiempo adicional para crear las cuentas si faltan.

Trabajaremos con tres terminales:

| Terminal | Cuenta | Uso |
| --- | --- | --- |
| **A** | Tu usuario habitual con sudo | Preparar el directorio y cambiar su configuración |
| **B** | `ana` | Crear archivos y comprobar permisos como Ana |
| **C** | `bruno` | Crear archivos y comprobar permisos como Bruno |

> [!NOTE]
> Reemplazá `cristian` por tu usuario habitual. Los comandos de SSH usan el reenvío del curso, puerto 2222 del anfitrión hacia SSH de la VM. Si tenés otra conexión, usá sus datos. También podés trabajar desde terminales de la propia VM.

> [!IMPORTANT]
> Antes de cada bloque, comprobá la terminal indicada. Los errores de acceso forman parte de la práctica: no agregues `sudo` en las sesiones de Ana y Bruno para evitarlos.

## 0. Preparación para todos

### 1. Entrá como administrador

**Terminal A — desde la máquina anfitriona.**

```bash
ssh -p 2222 cristian@localhost
```


### 2. Comprobá si existen las cuentas y el grupo

**Terminal A.**

```bash
getent passwd ana
getent passwd bruno
getent group desarrollo
```

- Si una consulta muestra una entrada, ese elemento ya existe: no lo vuelvas a crear.
- Si no muestra nada, ejecutá **solamente el comando correspondiente** de esta tabla.

| Si falta… | Comando |
| --- | --- |
| Ana | `sudo adduser ana` |
| Bruno | `sudo adduser bruno` |
| El grupo desarrollo | `sudo addgroup desarrollo` |

Al crear cada usuario, elegí una contraseña de laboratorio, repetila y completá su nombre. Podés dejar vacíos los demás datos y aceptar la confirmación final con `Enter`. La contraseña no se muestra al escribirla.

Si las cuentas ya existían y olvidaste sus contraseñas, desde la cuenta administradora podés asignar otras con `sudo passwd ana` o `sudo passwd bruno`. No hace falta eliminar ni recrear los usuarios.

### 3. Asegurá la pertenencia al grupo

**Terminal A — tanto si hiciste el laboratorio anterior como si no.**

```bash
sudo adduser ana desarrollo
sudo adduser bruno desarrollo
id ana
id bruno
getent group desarrollo
```

Si ya eran miembros, `adduser` lo informará. Ambas cuentas deben incluir `desarrollo` y no deben pertenecer a `sudo`. Para los ejemplos suponemos los grupos principales habituales `ana` y `bruno`. Los números UID/GID pueden variar.

Con esto ya está preparado lo necesario del laboratorio anterior. **No se necesita su archivo `informe.txt` ni se modifica `/srv/laboratorio-clase8`.**

### 4. Abrí sesiones nuevas de Ana y Bruno

Cerrá cualquier sesión vieja de estas cuentas para que se carguen los grupos actuales.

**Terminal B — desde la máquina anfitriona:**

```bash
ssh -p 2222 ana@localhost
```

**Terminal C — desde la máquina anfitriona:**

```bash
ssh -p 2222 bruno@localhost
```

En **cada una**, ejecutá:

```bash
whoami
id
```

En B debe aparecer `ana`; en C, `bruno`. En ambas, `id` debe incluir `desarrollo`.

> [!NOTE]
> Si trabajás desde la consola de Debian sin SSH, abrí otras dos terminales como tu usuario administrador. En una ejecutá `sudo -iu ana` y en otra `sudo -iu bruno`. Después comprobá `whoami` e `id`. A partir de ahí realizá los ejercicios sin sudo dentro de esas sesiones.

### 5. Comprobá el lugar de trabajo

**Terminal A.**

```bash
ls -ld /srv/equipo
```

Para empezar esta guía esperamos que indique que no existe. Si ya existe porque hiciste otras pruebas, conservá ese directorio: elegí otro nombre libre, por ejemplo `/srv/equipo-lab8`, y reemplazá `/srv/equipo` por esa ruta **en todos los comandos del laboratorio**. No continúes sobre archivos anteriores: las pruebas de umask necesitan archivos nuevos.

## 1. Crear el espacio del equipo

**Terminal A.**

Ejecutá un comando por vez:

```bash
sudo mkdir /srv/equipo
sudo chown root /srv/equipo
sudo chgrp desarrollo /srv/equipo
sudo chmod 770 /srv/equipo
ls -ld /srv/equipo
```

Esperamos que la línea comience así:

```text
drwxrwx--- ... root desarrollo ... /srv/equipo
```

- El owner es root; el grupo es desarrollo.
- `770` permite listar, atravesar y modificar entradas al owner y al grupo.
- Otros usuarios no tienen acceso por esos permisos.

Los dos cambios de propiedad también podrían expresarse con `sudo chown root:desarrollo /srv/equipo`. Acá usamos `chown` y `chgrp` por separado para observar qué cambia cada uno.



## 2. Conservar el grupo con SGID

### 1. Creá un archivo antes de activar SGID

**Terminal B — Ana.**

```bash
umask 007
echo 'Primera prueba de Ana' > /srv/equipo/antes-sgid.txt
ls -l /srv/equipo/antes-sgid.txt
```

En la configuración habitual de Debian, esperamos:

```text
-rw-rw---- ... ana ana ... /srv/equipo/antes-sgid.txt
```

El directorio tiene grupo `desarrollo`, pero el archivo nuevo tomó el grupo principal de Ana. Así, dar escritura al grupo del archivo no alcanza para compartirlo con Bruno.

Si aparece otro grupo, revisá `id` y `ls -ld /srv/equipo` con el docente: puede haber una configuración de herencia diferente.

### 2. Activá SGID en el directorio

**Terminal A.**

```bash
sudo chmod 2770 /srv/equipo
ls -ld /srv/equipo
```

Resultado esperado:

```text
drwxrws--- ... root desarrollo ... /srv/equipo
```

El `2` inicial activa SGID. La `s` ocupa la posición de ejecución del grupo. Los archivos nuevos tomarán `desarrollo` como grupo; el owner seguirá siendo quien los crea.

### 3. Corregí el archivo que ya existía

**Terminal B — Ana.**

```bash
ls -l /srv/equipo/antes-sgid.txt
chgrp desarrollo /srv/equipo/antes-sgid.txt
ls -l /srv/equipo/antes-sgid.txt
```

SGID no cambió el archivo anterior. Ana puede cambiar el grupo del archivo a `desarrollo` porque es el owner y pertenece a ese grupo. Ahora debe verse `ana desarrollo`.

## 3. Dar escritura y elegir la umask

### 1. Creá un informe con umask 022

**Terminal B — Ana.**

```bash
umask 022
echo 'Informe de Ana' > /srv/equipo/informe-ana.txt
ls -l /srv/equipo/informe-ana.txt
```

Resultado esperado:

```text
-rw-r--r-- ... ana desarrollo ... /srv/equipo/informe-ana.txt
```

SGID conservó el grupo correcto, pero la umask quitó su escritura. El archivo quedó con `644`.

### 2. Intentá editarlo como Bruno

**Terminal C — Bruno.**

```bash
cat /srv/equipo/informe-ana.txt
echo 'Revisado por Bruno' >> /srv/equipo/informe-ana.txt
```

La lectura funciona y la escritura responde **Permiso denegado**. Antes de cambiar algo, revisá:

```bash
id
ls -l /srv/equipo/informe-ana.txt
ls -ld /srv/equipo
namei -l /srv/equipo/informe-ana.txt
```

Bruno pertenece al grupo y puede atravesar la ruta. Lo que falta es `w` para G en el archivo.

### 3. Corregí ese archivo con chmod

**Terminal B — Ana, owner del archivo.**

```bash
chmod g+w /srv/equipo/informe-ana.txt
ls -l /srv/equipo/informe-ana.txt
chmod 660 /srv/equipo/informe-ana.txt
ls -l /srv/equipo/informe-ana.txt
```

Primero agregamos escritura al grupo: `644` pasa a `664`. Después usamos la forma octal para dejar `660`, quitando el acceso de otros. No cambian el owner ni el grupo.

**Terminal C — Bruno:**

```bash
echo 'Revisado por Bruno' >> /srv/equipo/informe-ana.txt
cat /srv/equipo/informe-ana.txt
```

Ahora debe verse:

```text
Informe de Ana
Revisado por Bruno
```

### 4. Prepará las próximas creaciones

En **B y C**, cada uno en su propia sesión:

```bash
umask 007
umask
```

Esperamos `0007`. La umask pertenece a la sesión: cambiarla como Ana no cambia la de Bruno. Tampoco modifica archivos existentes.

**Terminal C — Bruno:**

```bash
echo 'Informe de Bruno' > /srv/equipo/informe-bruno.txt
ls -l /srv/equipo/informe-bruno.txt
```

Ahora nace directamente con el grupo y los permisos deseados:

```text
-rw-rw---- ... bruno desarrollo ... /srv/equipo/informe-bruno.txt
```

**Terminal B — Ana:**

```bash
echo 'Revisado por Ana' >> /srv/equipo/informe-bruno.txt
cat /srv/equipo/informe-bruno.txt
```

Resultado:

```text
Informe de Bruno
Revisado por Ana
```

**SGID conservó el grupo; umask permitió que las creaciones habituales nacieran con escritura grupal.** No hubo que repetir `chmod` en el informe nuevo.

## 4. Diagnosticar una ruta sin x

### 1. Quitá temporalmente la búsqueda para el grupo

**Terminal A.**

```bash
sudo chmod g-x /srv/equipo
ls -ld /srv/equipo
```

Ahora se verá `drwxrwS---`. La `S` indica que SGID sigue activo, pero el grupo no tiene `x`.

### 2. Compará listar nombres con acceder al archivo

**Terminal C — Bruno.**

```bash
ls -1 --color=never /srv/equipo
cat /srv/equipo/informe-ana.txt
namei -l /srv/equipo/informe-ana.txt
```

Bruno puede ver los nombres porque conserva `r` en el directorio. `cat` falla aunque el archivo tenga lectura: falta `x` para buscar ese nombre dentro de `/srv/equipo`. `namei` ayuda a localizar el componente que bloquea el recorrido.

### 3. Restaurá la búsqueda y repetí la lectura

**Terminal A:**

```bash
sudo chmod g+x /srv/equipo
ls -ld /srv/equipo
```

**Terminal C — Bruno:**

```bash
cat /srv/equipo/informe-ana.txt
```

La lectura vuelve a funcionar. El directorio debe quedar otra vez como `drwxrws---` antes de seguir.

## 5. Borrar un archivo ajeno

### 1. Creá un archivo descartable como Bruno

**Terminal C.**

```bash
echo 'Archivo descartable de Bruno' > /srv/equipo/prueba-borrado.txt
ls -l /srv/equipo/prueba-borrado.txt
```

El owner debe ser Bruno; el grupo, desarrollo; los permisos, `660`.

### 2. Borralo como Ana

**Terminal B.**

```bash
rm /srv/equipo/prueba-borrado.txt
ls /srv/equipo
```

El borrado funciona aunque Ana no sea el owner del archivo: tiene `w+x` en el directorio de esta práctica. `rm` quita el nombre de la lista del directorio.

## 6. Verificación final

### 1. Revisá el resultado como administrador

**Terminal A.**

```bash
id ana
id bruno
ls -ld /srv/equipo
sudo ls -l /srv/equipo
sudo cat /srv/equipo/informe-ana.txt
sudo cat /srv/equipo/informe-bruno.txt
```

Esperamos:

| Elemento | Owner y grupo | Permisos |
| --- | --- | --- |
| `/srv/equipo` | root:desarrollo | `2770`, `drwxrws---` |
| `antes-sgid.txt` | ana:desarrollo | `660`, `-rw-rw----` |
| `informe-ana.txt` | ana:desarrollo | `660`, `-rw-rw----` |
| `informe-bruno.txt` | bruno:desarrollo | `660`, `-rw-rw----` |

Cada informe debe tener su línea original y la revisión del compañero. El archivo descartable `prueba-borrado.txt` ya no debe estar.

### 2. Comprobá el rechazo a un usuario ajeno

**Terminal A — sin sudo.**

```bash
id
cat /srv/equipo/informe-ana.txt
```

Si tu usuario habitual no pertenece a desarrollo y no es root, `cat` debe responder **Permiso denegado** por el directorio. La lectura anterior funcionó con sudo porque se ejecutó como root.

Si tu cuenta también pertenece a desarrollo, no representa a un usuario ajeno. En ese caso, desde A podés comprobarlo con la cuenta `nobody` de Debian:

```bash
id nobody
sudo -u nobody cat /srv/equipo/informe-ana.txt
```

Primero verificá que `nobody` no pertenezca a desarrollo. Aquí sudo se utiliza para ejecutar la prueba **como nobody**, no como root; esperamos el rechazo.

### 3. Respondé a partir de lo observado

1. ¿Qué cambió `chgrp` y qué cambió `chmod`?
2. ¿Por qué activar SGID no corrigió `antes-sgid.txt`?
3. ¿Por qué el informe creado con umask 022 tenía el grupo correcto pero Bruno no podía editarlo?
4. ¿Por qué configuramos umask en las dos sesiones?
5. ¿Cómo pudo Bruno listar nombres cuando no podía leer un archivo que tenía `r`?
6. ¿Por qué Ana pudo borrar el archivo descartable de Bruno?
7. ¿Qué significa la `s` en `drwxrws---`?

### 4. Conservá el entorno

Dejá `/srv/equipo`, los informes, Ana, Bruno y desarrollo para consultas posteriores. Cerrá las sesiones B y C con `exit` y después la sesión A. Si usaste `sudo -iu`, el primer `exit` vuelve a tu usuario habitual.

La umask que ajustamos es de esas sesiones; no modificamos archivos de inicio. Al abrir otra sesión, consultala nuevamente antes de crear más archivos compartidos.

## Resumen del laboratorio

- El directorio controla quién puede crear y borrar nombres; el archivo controla lectura y modificación del contenido.
- `chown` y `chgrp` cambian propiedad; `chmod` cambia permisos.
- `namei -l` ayuda a revisar el recorrido de una ruta.
- SGID conserva el grupo en objetos nuevos; umask limita sus permisos iniciales.

## Enlaces útiles y referencias

- [Laboratorio 7 — Usuarios, grupos e identidad](../lab7/lab7.md) — repaso opcional; no es requisito para ejecutar esta guía.
- Ayuda en Debian: `man chmod`, `man chown`, `man chgrp`, `man namei` y `help umask`.

-----

<p align="center">
<img src="../img/logos.footer.gray.webp">
</p>
