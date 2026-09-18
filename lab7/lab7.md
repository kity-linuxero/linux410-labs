# Laboratorio 7 - Usuarios, grupos e identidad

## Objetivo

- Consultar la identidad de una sesión y distinguirla del uso de `sudo`.
- Interpretar datos de cuentas y grupos con `getent`.
- Crear dos usuarios comunes y un grupo de trabajo.
- Comprobar la diferencia entre los grupos registrados para una cuenta y los de una sesión abierta.
- Leer los permisos tradicionales de Unix y verificar el acceso con distintas identidades.

### Continuamos con la VM Debian

Usamos la VM `Lab2`, con Debian 13, y el acceso por SSH de los laboratorios anteriores. Este **Lab 7 acompaña la clase 8** y continúa el trabajo de edición del [Laboratorio 6](../lab6/lab6.md).

Vamos a crear las cuentas `ana` y `bruno`, el grupo `desarrollo` y un archivo de prueba en `/srv/laboratorio-clase8`. Conservaremos este entorno para la clase de permisos.

Trabajaremos con **dos terminales de la máquina anfitriona**:

| Terminal | Cuenta | Uso |
| --- | --- | --- |
| **A** | Tu usuario habitual, por ejemplo `cristian` | Administración y consultas. Usa `sudo` cuando se indica. |
| **B** | Primero `bruno`, después `ana` | Comprobar accesos como usuario común. No usa `sudo`. |

> [!NOTE]
> Reemplazá `cristian` por tu usuario habitual si elegiste otro nombre al instalar Debian. Ana y Bruno son cuentas nuevas de esta práctica; no las agregues al grupo `sudo`.

> [!IMPORTANT]
> Leé en qué terminal se realiza cada paso. La sesión de Bruno debe permanecer abierta mientras el administrador lo agrega al grupo: esa comparación es parte del laboratorio.

## 0. Preparar la sesión

### 1. Conectate desde la terminal A

```bash
ssh -p 2222 cristian@localhost
```

Confirmá dónde estás trabajando:

```bash
whoami
hostname
pwd
id
groups
```

Deberías ver tu usuario habitual, el equipo `lab2-vm` y tu directorio personal.

Los números de UID/GID y la lista de grupos pueden variar entre instalaciones.

Ejemplo de salida de comandos:

```bash
cristian

lab2-vm

/home/cristian

uid=1000(cristian) gid=1000(cristian) grupos=1000(cristian),24(cdrom),25(floppy),27(sudo),29(audio),30(dip),44(video),46(plugdev),100(users),101(netdev),103(bluetooth)

cristian cdrom floppy sudo audio dip video plugdev users netdev bluetooth

```

### 2. Repasá root y sudo

```bash
whoami
sudo whoami
whoami
```

En nuestro ejemplo, las respuestas son `cristian`, `root` y `cristian`. `sudo` pide la contraseña de tu usuario habitual cuando corresponde; ejecutar ese comando no transforma toda la sesión en una sesión de root.

### 3. Comprobá que los nombres y el directorio estén disponibles

```bash
getent passwd ana
getent passwd bruno
getent group desarrollo
ls -ld /srv/laboratorio-clase8
```

En la primera ejecución, las consultas de `getent` no muestran ninguna entrada y `ls` informa que el directorio no existe. Son los resultados esperados antes de crear el entorno: la única salida visible es la de `ls`.

```bash
ls: no se puede acceder a '/srv/laboratorio-clase8': No existe el fichero o el directorio
```


## 1. Consultar cuentas y grupos

**Terminal A — usuario habitual.**

### 1. Compará nombres e identificadores

```bash
ls -l /etc/hosts
ls -ln /etc/hosts
```

Localizá el owner y el grupo. En la segunda salida aparecen sus números; el archivo y sus permisos no cambiaron.

```bash
cristian@lab2-vm:~$ ls -l /etc/hosts
-rw-r--r-- 1 root root 187 ago 27 12:05 /etc/hosts
cristian@lab2-vm:~$ ls -ln /etc/hosts
-rw-r--r-- 1 0 0 187 ago 27 12:05 /etc/hosts

```

### 2. Consultá la cuenta y sus grupos

```bash
getent passwd cristian
getent group sudo
id cristian
```

En la entrada de `passwd`, identificá nombre, UID, GID principal, directorio personal e intérprete. En la entrada de `sudo`, identificá el GID y la lista de miembros.

Las dos primeras líneas se ven así; `id cristian` repite la salida que ya viste en el paso 0:

```bash
cristian:x:1000:1000:cristian,,,:/home/cristian:/bin/bash
sudo:x:27:cristian
```

`getent` consulta las fuentes configuradas en el sistema. En esta VM trabajamos con cuentas locales. Leer o buscar en `/etc/passwd` solo consulta ese archivo.

### 3. Consultá el estado de contraseña de root

```bash
sudo passwd -S root
```

Resultado esperado
```bash
cristian@lab2-vm:~$ sudo passwd -S root
root L 2026-08-27 0 99999 7 -1
```

En la VM instalada siguiendo el curso, el segundo campo debe mostrar `L`: la contraseña está bloqueada. Acabamos de usar `sudo whoami` correctamente; bloquear la contraseña de root no impide esa elevación autorizada.

No cambies el estado de root ni muestres el contenido de `/etc/shadow`. Para esta comprobación alcanza con `passwd -S`, que no expone hashes.

### 4. Observá una cuenta de servicio

```bash
getent passwd www-data
```

Deberías ver:

```bash
www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin
```

Compará su UID, home e intérprete con los de tu cuenta. En Debian es habitual encontrar `/usr/sbin/nologin` como intérprete de `www-data`. Que exista la cuenta no demuestra que haya un servidor web instalado o funcionando.

## 2. Crear las cuentas y el grupo

**Terminal A — usuario habitual con sudo.**

### 1. Creá las cuentas de Ana y Bruno

Ejecutá un comando por vez y completá sus preguntas:

```bash
sudo adduser ana
sudo adduser bruno
```

Para cada cuenta:

1. Elegí una contraseña de laboratorio y repetila. No reutilices una contraseña personal.
2. Indicá `Ana` o `Bruno` en el campo de nombre completo.
3. Dejá los demás datos opcionales vacíos con `Enter`.
4. Confirmá la información cuando el programa lo solicite.

Al escribir las contraseñas no aparecen caracteres en pantalla. Guardalas para las conexiones de la terminal B.

El diálogo completo de `sudo adduser ana` se ve así:

```text
Nueva contraseña:
Vuelva a escribir la nueva contraseña:
passwd: contraseña actualizada correctamente
Cambiando la información de usuario para ana
Introduzca el nuevo valor, o pulse INTRO para usar el valor predeterminado
	Nombre completo []: Ana
	Número de habitación []:
	Teléfono del trabajo []:
	Teléfono de casa []:
	Otro []:
Is the information correct? [Y/n]
```

> [!NOTE]
> La última pregunta aparece en inglés, `Is the information correct? [Y/n]`, aunque el resto del programa esté en castellano. `Enter` acepta la opción predeterminada; también sirve escribir `S` o `Y`. Solo `n` vuelve a pedir los datos.

### 2. Verificá las cuentas creadas

```bash
getent passwd ana
getent passwd bruno
getent group ana
getent group bruno
id ana
id bruno
ls -ld /home/ana /home/bruno
sudo passwd -S ana
sudo passwd -S bruno
```

Las primeras siete consultas devuelven, en orden:

```bash
ana:x:1001:1001:Ana,,,:/home/ana:/bin/bash
bruno:x:1002:1002:Bruno,,,:/home/bruno:/bin/bash
ana:x:1001:
bruno:x:1002:
uid=1001(ana) gid=1001(ana) grupos=1001(ana),100(users)
uid=1002(bruno) gid=1002(bruno) grupos=1002(bruno),100(users)
drwx------ 2 ana   ana   4096 sep 18 01:03 /home/ana
drwx------ 2 bruno bruno 4096 sep 18 01:04 /home/bruno
```

Los UID y GID pueden variar según cuántas cuentas se hayan creado antes. Comprobá que cada cuenta tenga home e intérprete y que ninguna pertenezca a `sudo`. Con la configuración habitual de Debian, cada una tiene un grupo principal con su mismo nombre; pueden aparecer otras pertenencias predeterminadas, como `users`.

En `passwd -S` esperamos `P`, porque acabamos de asignar una contraseña. Eso describe la contraseña, no todas las condiciones posibles de ingreso.

Ejemplo:
```bash
sudo passwd -S ana
ana P 2026-09-18 0 99999 7 -1
```

> [!NOTE]
> `getent group ana` puede mostrar la lista de miembros vacía. Ana pertenece a ese grupo como grupo principal, indicado por el GID en su entrada de `passwd`; no necesita aparecer también como miembro suplementario.

### 3. Creá el grupo de trabajo y agregá solamente a Ana

```bash
sudo addgroup desarrollo
sudo adduser ana desarrollo
getent group desarrollo
id ana
id bruno
```

Las últimas tres consultas devuelven:

```bash
desarrollo:x:1003:ana
uid=1001(ana) gid=1001(ana) grupos=1001(ana),100(users),1003(desarrollo)
uid=1002(bruno) gid=1002(bruno) grupos=1002(bruno),100(users)
```

Ana debe aparecer en `desarrollo`. **Bruno todavía no**: primero vamos a abrir una sesión suya.

## 3. Preparar el archivo del ejercicio

**Terminal A — usuario habitual con sudo.**

Necesitamos un archivo que pertenezca a Ana y al grupo `desarrollo` para comprobar quién puede leerlo y quién no. Lo armamos en cuatro pasos, un comando por vez.

### 1. Creá el archivo original en tu home

```bash
mkdir -p ~/laboratorio-clase8
cd ~/laboratorio-clase8
echo 'Informe de desarrollo' > informe-base.txt
cat informe-base.txt
```

### 2. Creá el directorio de la práctica

```bash
sudo mkdir /srv/laboratorio-clase8
ls -ld /srv/laboratorio-clase8
```

Como lo creamos con `sudo`, el directorio queda a nombre de `root`. Cualquiera puede entrar y listar su contenido, pero solo root puede crear o borrar archivos adentro.

```text
drwxr-xr-x 2 root root 4096 sep 18 01:05 /srv/laboratorio-clase8
```

### 3. Copiá el archivo al directorio

```bash
sudo cp informe-base.txt /srv/laboratorio-clase8/informe.txt
ls -l /srv/laboratorio-clase8/informe.txt
```

La copia queda a nombre de `root`, porque la hicimos con `sudo`:

```text
-rw-r--r-- 1 root root 22 sep 18 01:05 /srv/laboratorio-clase8/informe.txt
```

### 4. Asignale el owner, el grupo y los permisos

```bash
sudo chown ana:desarrollo /srv/laboratorio-clase8/informe.txt
sudo chmod 640 /srv/laboratorio-clase8/informe.txt
ls -l /srv/laboratorio-clase8/informe.txt
```

`chown` define el owner y el grupo del archivo. `chmod 640` deja lectura y escritura para el owner, solo lectura para el grupo y ningún permiso para el resto. En esta clase los usamos para dejar el archivo listo; los vamos a estudiar en detalle en la próxima.

La línea debe comenzar así; tamaño y fecha pueden variar:

```text
-rw-r----- 1 ana desarrollo 22 sep 18 01:05 /srv/laboratorio-clase8/informe.txt
```

> [!IMPORTANT]
> Hacé esta preparación una sola vez, después de comprobar en el paso 0 que el directorio no existía. Si repetís la copia, el archivo vuelve a tener una sola línea y se pierde lo que hayan agregado Ana o Bruno.

Dejamos el archivo en `/srv` y no en un home para que los permisos del directorio personal no interfieran con el ejemplo. Todavía no es el directorio colaborativo de la clase 9: acá cada uno solo va a leer o escribir el archivo según su identidad.

Antes de continuar, completá esta predicción:

| Identidad | Conjunto que se aplica | ¿Puede leer? | ¿Puede escribir? |
| --- | --- | --- | --- |
| Ana, owner | U: `rw-` | | |
| Bruno antes de pertenecer a `desarrollo` | O: `---` | | |
| Bruno con `desarrollo` en una sesión nueva | G: `r--` | | |
| Tu cuenta habitual, fuera de `desarrollo` y sin sudo | O: `---` | | |

## 4. Comparar una sesión existente con una nueva

### 1. Abrí la sesión de Bruno en la terminal B

Desde **otra terminal de la máquina anfitriona**, conectate con la contraseña que elegiste para Bruno:

```bash
ssh -p 2222 bruno@localhost
```

Comprobá identidad, grupos y acceso:

```bash
whoami
id
groups
cat /srv/laboratorio-clase8/informe.txt
```

Deberías ver:

```bash
bruno
uid=1002(bruno) gid=1002(bruno) grupos=1002(bruno),100(users)
bruno users
cat: /srv/laboratorio-clase8/informe.txt: Permiso denegado
```

`whoami` devuelve `bruno`, `id` todavía no incluye `desarrollo` y `cat` responde **Permiso denegado** o **Permission denied**. Es un rechazo esperado. **Dejá esta sesión abierta.**

### 2. Agregá a Bruno desde la terminal A

Volvé a la terminal del administrador:

```bash
sudo adduser bruno desarrollo
getent group desarrollo
id bruno
```

```bash
desarrollo:x:1003:ana,bruno
uid=1002(bruno) gid=1002(bruno) grupos=1002(bruno),100(users),1003(desarrollo)
```

El grupo ahora incluye a Ana y Bruno. El orden de los nombres no importa.

### 3. Volvé a la terminal B sin reconectarte

En la sesión de Bruno que estaba abierta:

```bash
id
id bruno
cat /srv/laboratorio-clase8/informe.txt
```

Las tres salidas, una debajo de la otra:

```bash
uid=1002(bruno) gid=1002(bruno) grupos=1002(bruno),100(users)
uid=1002(bruno) gid=1002(bruno) grupos=1002(bruno),100(users),1003(desarrollo)
cat: /srv/laboratorio-clase8/informe.txt: Permiso denegado
```

Compará los resultados:

- `id` sigue mostrando los grupos de la sesión existente, sin `desarrollo`.
- `id bruno` consulta los datos registrados para la cuenta y sí incluye `desarrollo`.
- `cat` sigue rechazando la lectura: el proceso conserva los grupos anteriores.

### 4. Cerrá la sesión de Bruno y abrí una nueva

En la **terminal B**, salí de la VM:

```bash
exit
```

Ya en la **máquina anfitriona**, volvé a conectarte:

```bash
ssh -p 2222 bruno@localhost
```

Dentro de la nueva sesión:

```bash
whoami
id
groups
cat /srv/laboratorio-clase8/informe.txt
```

Ahora `id` incluye `desarrollo` y la lectura funciona:

```bash
bruno
uid=1002(bruno) gid=1002(bruno) grupos=1002(bruno),100(users),1003(desarrollo)
bruno users desarrollo
Informe de desarrollo
```

No fue necesario reiniciar la VM. La sesión nueva cargó las pertenencias actualizadas.

## 5. Comprobar lectura y escritura según UGO

### 1. Intentá escribir como Bruno

**Terminal B — sesión nueva de Bruno.**

```bash
echo 'Agregado por Bruno' >> /srv/laboratorio-clase8/informe.txt
cat /srv/laboratorio-clase8/informe.txt
```

Deberías ver:

```bash
bash: /srv/laboratorio-clase8/informe.txt: Permiso denegado
Informe de desarrollo
```

La escritura debe responder **Permiso denegado**. La lectura sigue funcionando y el contenido continúa siendo una sola línea. Bruno tiene `r--` por el grupo, sin permiso de escritura.

No agregues `sudo` para hacer funcionar la escritura: estamos comprobando el acceso de Bruno.

### 2. Cambiá a una sesión de Ana

En la **terminal B**, cerrá la conexión de Bruno:

```bash
exit
```

Desde la **máquina anfitriona**, conectate como Ana:

```bash
ssh -p 2222 ana@localhost
```

Verificá identidad, leé y agregá una línea:

```bash
whoami
id
cat /srv/laboratorio-clase8/informe.txt
echo 'Revisado por Ana' >> /srv/laboratorio-clase8/informe.txt
cat /srv/laboratorio-clase8/informe.txt
```

El resultado debe ser:

```text
Informe de desarrollo
Revisado por Ana
```

Ana usa el conjunto U porque es el owner. Que también pertenezca a `desarrollo` no hace que se sumen los permisos de U y G.

### 3. Comprobá el caso de otros usuarios

**Terminal A — tu usuario habitual, sin sudo.**

```bash
whoami
id
cat /srv/laboratorio-clase8/informe.txt
```

Deberías ver:

```bash
cristian
cat: /srv/laboratorio-clase8/informe.txt: Permiso denegado
```

Si tu cuenta no pertenece a `desarrollo`, la lectura debe fallar: le corresponde O, `---`. Estar autorizado para usar `sudo` no significa que todos tus comandos se ejecuten como root.

## 6. Verificación final

### 1. Revisá los resultados como administrador

**Terminal A.**

```bash
id ana
id bruno
getent group desarrollo
ls -l /srv/laboratorio-clase8/informe.txt
ls -ln /srv/laboratorio-clase8/informe.txt
sudo cat /srv/laboratorio-clase8/informe.txt
sudo cat /srv/laboratorio-clase8/informe.txt > ~/laboratorio-clase8/informe-verificado.txt
diff -u ~/laboratorio-clase8/informe-base.txt ~/laboratorio-clase8/informe-verificado.txt
```

Las dos variantes de `ls` y el contenido leído con `sudo`:

```bash
-rw-r----- 1 ana desarrollo 39 sep 18 01:07 /srv/laboratorio-clase8/informe.txt
-rw-r----- 1 1001 1003 39 sep 18 01:07 /srv/laboratorio-clase8/informe.txt
Informe de desarrollo
Revisado por Ana
```

Guardamos una copia del resultado para compararla con el original usando `diff -u`, como en el laboratorio anterior. La comparación debe mostrar una sola línea agregada:

```diff
--- /home/cristian/laboratorio-clase8/informe-base.txt	2026-09-18 01:05:25 -0300
+++ /home/cristian/laboratorio-clase8/informe-verificado.txt	2026-09-18 01:07:29 -0300
@@ -1 +1,2 @@
 Informe de desarrollo
+Revisado por Ana
```

Debe aparecer únicamente la línea agregada por Ana. No debe existir una línea agregada por Bruno. Los permisos siguen siendo `rw-r-----` y el owner y grupo siguen siendo `ana desarrollo`.

### 2. Completá la tabla y respondé

Volvé a la predicción del paso 3 y contrastala con los resultados observados.

1. ¿Qué cambia entre `ls -l` y `ls -ln`?
2. ¿Dónde se registra el GID principal de una cuenta?
3. ¿Por qué `id` e `id bruno` mostraron grupos diferentes en la sesión anterior?
4. ¿Por qué Bruno pudo leer después de reconectarse, pero siguió sin poder escribir?
5. ¿Qué conjunto se aplicó a Ana? ¿Se sumó al de su grupo?
6. ¿Por qué tu cuenta administradora pudo recibir “Permiso denegado” sin sudo?
7. ¿Qué informa `passwd -S` y qué no permite concluir sobre todas las vías de acceso?
8. ¿Por qué una cuenta de servicio puede tener `nologin` como intérprete?

### 3. Conservá el entorno y cerrá las conexiones

No borres Ana, Bruno, `desarrollo` ni los directorios de la práctica. Los retomaremos en la clase 9.

En la **terminal B**, salí de Ana:

```bash
exit
```

En la **terminal A**, cerrá la conexión administrativa:

```bash
exit
```

Si ya terminaste de usar la VM, podés apagarla desde su consola como en los laboratorios anteriores. No la apagues mientras otra persona la esté utilizando.

## Resumen del laboratorio

- Los nombres de usuarios y grupos se corresponden con UID y GID.
- `getent` consulta las cuentas y los grupos; `passwd -S` informa el estado de contraseña sin mostrar el hash.
- `adduser` crea las cuentas y también permite agregarlas a un grupo existente.
- Una sesión abierta conserva sus grupos aunque cambie la pertenencia registrada.
- Una sesión nueva permite comprobar los grupos actualizados.
- UGO selecciona los permisos según la identidad: los conjuntos no se suman.
- Probamos los rechazos de acceso como parte del resultado esperado.

## Enlaces útiles y referencias

- [Clase 8 — Usuarios, grupos e identidad](https://linux.idepba.com.ar/clase8.html)
- [Laboratorio 6 — Edición de archivos de texto](../lab6/lab6.md)
- [Debian 13 — adduser(8)](https://manpages.debian.org/trixie/adduser/adduser.8.en.html)
- [Debian 13 — getent(1)](https://manpages.debian.org/trixie/manpages/getent.1.en.html)
- [Debian 13 — passwd(1)](https://manpages.debian.org/trixie/passwd/passwd.1.en.html)

-----

<p align="center">
<img src="../img/logos.footer.gray.webp">
</p>
