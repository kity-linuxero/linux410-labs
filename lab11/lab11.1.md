# Laboratorio 11.1 - Ampliar la partición raíz

## Objetivo

- Dejar de usar la swap y sacarla del arranque.
- Borrar la partición de swap y agrandar `sda2` sobre el espacio que queda libre, con `fdisk`.
- Ampliar el sistema de archivos ext4 con `/` montada, sin reiniciar.
- Comprobar después de reiniciar que el sistema arranca sin demoras ni errores.

### Punto de partida

Usamos la VM Debian 13 del curso y la cuenta administradora con `sudo`, por ejemplo `cristian`. **Alcanza con tener la VM instalada y el acceso por SSH del [Laboratorio 3](../lab3/lab3.md).** El disco `sda` es de 20 GB, con tabla GPT y tres particiones:

```text
sda1  ESP   967M   vfat  /boot/efi
sda2  /     18,1G  ext4
sda3  swap  1005M
```

Una partición solo puede crecer hacia espacio libre que esté pegado a su final. Hoy no hay espacio libre en el disco, y además la swap está justo detrás de `sda2`. Para tener algo donde crecer, vamos a borrar la swap. Es un ejemplo: en una máquina real habría que pensar mejor qué se sacrifica. Lo que queremos mostrar es que, si hay espacio contiguo, la raíz ext4 se amplía en caliente, con el sistema en marcha.

La VM queda sin swap y con 948 MiB de RAM. Para lo que hacemos en el curso alcanza.

> [!IMPORTANT]
> Antes de cambiar nada, sacá una instantánea de la VM (paso 1). Este laboratorio toca la tabla de particiones y el arranque. Si algo sale mal, volvés atrás con la instantánea.

> [!NOTE]
> Reemplazá `cristian` por tu usuario habitual. Los tamaños y los UUID de tu VM pueden ser otros. Si ya agregaste el disco del [Laboratorio 11.2](lab11.2.md), tu disco del sistema puede no llamarse `sda`. Confirmalo por el tamaño con `lsblk` antes de usar `fdisk` o `resize2fs`. Conviene hacer primero este laboratorio y después el 11.2.

## 0. Preparación y estado inicial

Desde la máquina anfitriona:

```bash
ssh -p 2222 cristian@localhost
```

Comprobá que estás en la VM:

```bash
hostname
```

Tiene que aparecer `lab2-vm` (o el nombre que le hayas dado). Anotá el estado de partida:

```bash
lsblk
df -h /
free -h
sudo swapon --show
```

Ejemplo de salida:

```text
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda      8:0    0   20G  0 disk 
├─sda1   8:1    0  967M  0 part /boot/efi
├─sda2   8:2    0 18,1G  0 part /
└─sda3   8:3    0 1005M  0 part [SWAP]
sr0     11:0    1 1024M  1 rom  
S.ficheros     Tamaño Usados  Disp Uso% Montado en
/dev/sda2         18G   1,5G   16G   9% /
               total       usado       libre  compartido   búf/caché  disponible
Mem:           948Mi       224Mi       733Mi       548Ki       119Mi       723Mi
Inter:         1,0Gi          0B       1,0Gi
NAME      TYPE       SIZE USED PRIO
/dev/sda3 partition 1005M   0B   -2
```

Fijate en tres cosas: el disco es de 20G, la raíz de 18G y la swap (`sda3`) está activa y viene después de `sda2`.

> [!TIP]
> `swapon`, `fdisk`, `resize2fs` y `blkid` viven en `/usr/sbin`, que no está en el `PATH` de un usuario común. Sin `sudo` responden «orden no encontrada». `lsblk`, `df` y `free` andan sin `sudo`.

## 1. Sacar una instantánea

En VirtualBox, seleccioná la VM `Lab2`, abrí la pestaña **Instantáneas** y apretá **Tomar**. Poné un nombre que te sirva para reconocerla, por ejemplo `lab11.1`, y aceptá.

![Tomar instantánea](../img/lab11/instantanea-tomar.png)

Podés sacarla con la VM encendida o apagada. Después de aceptar, la lista muestra tu instantánea y debajo el **Estado actual**. Desde ahí en adelante todo lo que hagas se guarda aparte.

![Lista de instantáneas](../img/lab11/instantanea-lista.png)

Para volver atrás más adelante: seleccioná la instantánea y apretá **Restaurar**. El sistema queda como estaba al sacarla y se pierden los cambios posteriores.

## 2. Dejar de usar la swap

Para borrar `sda3` primero hay que dejar de usarla:

```bash
sudo swapoff /dev/sda3
sudo swapon --show
free -h
```

`swapon --show` no imprime nada y `free -h` muestra la fila `Inter:` en cero:

```text
Inter:            0B          0B          0B
```

## 3. Sacar la swap del arranque

Todavía no borramos nada, pero hay que avisarle al sistema que esa swap va a desaparecer. Son dos lugares.

### 1. `/etc/fstab`

```bash
sudo nano /etc/fstab
```

Poné un `#` al principio de la línea de la swap (la que dice `swap` en el tercer campo):

```text
#UUID=bc71ad71-54d4-4cf4-b312-0496d791dc99 none            swap    sw              0       0
```

Guardá y salí (`Ctrl+O`, Enter, `Ctrl+X`). Si dejás esa línea, systemd espera 90 segundos al dispositivo en cada arranque y la unidad `swap.target` falla.

### 2. El archivo `resume`

```bash
cat /etc/initramfs-tools/conf.d/resume
```

```text
RESUME=UUID=bc71ad71-54d4-4cf4-b312-0496d791dc99
```

Esa línea le dice al initramfs en qué partición buscar una imagen de hibernación. La partición va a dejar de existir. Cambiala:

```bash
sudo nano /etc/initramfs-tools/conf.d/resume
```

Dejá solamente:

```text
RESUME=none
```

Regenerá el initramfs para que tome el cambio:

```bash
sudo update-initramfs -u
```

```text
update-initramfs: Generating /boot/initrd.img-6.12.105+deb13-amd64
```

> [!NOTE]
> Si te olvidás de este archivo, el initramfs busca un dispositivo que ya no existe y el arranque se demora. En una prueba con un UUID de swap cambiado, la etapa del kernel pasó de unos 3 segundos a 34.

### 3. Verificar antes de seguir

```bash
sudo systemctl daemon-reload
sudo findmnt --verify
```

```text
0 errores de sintaxis, 0 errores, 1 aviso
```

El aviso es el de `/media/cdrom0` («No se ha encontrado el medio»): viene de la instalación y es normal.

## 4. Borrar la swap y agrandar `sda2` con `fdisk`

Antes de seguir confirmá, por el tamaño, que `sda` es el disco de 20G del sistema:

```bash
lsblk
```

Abrí `fdisk` sobre ese disco:

```bash
sudo fdisk /dev/sda
```

`fdisk` avisa que el disco está en uso y recomienda desmontar. Es cierto, pero vamos a modificar la tabla de todos modos: no tocamos los datos de `sda2`, solo le cambiamos el final. Los cambios quedan en memoria hasta que escribas con `w`.

Dentro de `fdisk`, escribí estas órdenes en este orden:

1. `p` para ver la tabla. Tienen que aparecer `sda1`, `sda2` y `sda3`.
2. `d` y después `3`: borra la partición 3 (la swap).

```text
Se ha borrado la partición 3.
```

3. `e` y después `2`: cambia el tamaño de la partición 2. Cuando pregunte el tamaño nuevo, apretá Enter para aceptar el máximo. El máximo es hasta el final del disco, ahora que la swap ya no está.

```text
Nuevo <tamaño>{K,M,G,T,P} en bytes o <tamaño>S en sectores (lo predeterminado es 19,1G):
Se ha redimensionado la partición 2.
```

4. `p` otra vez para controlar:

```text
/dev/sda1      2048  1982463  1980416   967M Sistema EFI
/dev/sda2   1982464 41943006 39960543  19,1G Sistema de ficheros de Linux
```

5. `w` para escribir:

```text
Se ha modificado la tabla de particiones.
Se están sincronizando los discos.
```

Si algo no te convence antes de `w`, salí con `q` y no se guarda nada.

Comprobá:

```bash
lsblk
df -h /
```

```text
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda      8:0    0   20G  0 disk 
├─sda1   8:1    0  967M  0 part /boot/efi
└─sda2   8:2    0 19,1G  0 part /
sr0     11:0    1 1024M  1 rom  
S.ficheros     Tamaño Usados  Disp Uso% Montado en
/dev/sda2         18G   1,5G   16G   9% /
```

`lsblk` ya muestra `sda2` de 19,1G, y el kernel lo tomó sin reiniciar. Pero `df` sigue diciendo 18G. La partición creció y el sistema de archivos que está adentro todavía no.

## 5. Ampliar el sistema de archivos

```bash
sudo resize2fs /dev/sda2
```

```text
Filesystem at /dev/sda2 is mounted on /; on-line resizing required
old_desc_blocks = 3, new_desc_blocks = 3
The filesystem on /dev/sda2 is now 4995067 (4k) blocks long.
```

Con `/` montada, ext4 se amplía en caliente. Mirá el resultado:

```bash
df -h /
```

```text
S.ficheros     Tamaño Usados  Disp Uso% Montado en
/dev/sda2         19G   1,5G   17G   9% /
```

## 6. Reiniciar y comprobar

```bash
sudo systemctl reboot
```

Esperá un momento y volvé a entrar por SSH. Después ejecutá:

```bash
df -h /
lsblk
sudo swapon --show
free -h
systemd-analyze
systemctl --failed
systemctl is-system-running
sudo findmnt --verify
```

Qué tiene que pasar:

- `df -h /` muestra 19G y `lsblk` muestra `sda2` de 19,1G.
- `swapon --show` no imprime nada y `free -h` muestra la swap en cero.
- `systemd-analyze` informa unos pocos segundos en total. En nuestra VM fueron unos 4 segundos (2 del kernel y 2 del espacio de usuario).
- `systemctl --failed` dice `0 loaded units listed.` y `systemctl is-system-running` responde `running`.
- `findmnt --verify` termina con `0 errores de sintaxis, 0 errores, 1 aviso`.

## 7. Verificación final

### 1. Comprobá el estado

```bash
lsblk
df -h /
sudo swapon --show
```

La raíz ocupa casi todo el disco de 20G, `sda3` ya no existe y no hay swap activa.

### 2. Respondé a partir de lo observado

1. ¿Por qué `sda2` no podía crecer mientras existía `sda3`?
2. ¿Por qué hubo que desactivar la swap antes de borrar la partición?
3. Después del paso 4, `lsblk` mostraba 19,1G y `df` 18G. ¿Qué faltaba y por qué?
4. ¿Para qué tocamos `/etc/fstab` y `/etc/initramfs-tools/conf.d/resume`? ¿Qué habría pasado si no?
5. ¿Qué hubieras hecho si algo salía mal en el paso 4?

### 3. Cerrá la sesión

```bash
exit
```

> [!NOTE]
> Con espacio libre detrás de la raíz, el procedimiento es el mismo sin el paso de la swap. GParted Live hace lo mismo con una interfaz gráfica: se arranca la VM desde su ISO y se arrastra el borde de la partición. No lo usamos en este laboratorio.

## Resumen del laboratorio

- Una partición solo puede crecer hacia espacio libre contiguo. La swap que estaba detrás de `sda2` lo impedía, y borrarla dejó el espacio libre.
- Antes de borrar la swap hay que desactivarla (`swapoff`) y sacarla de `fstab` y de `RESUME`. Si no, el arranque se demora o falla.
- `fdisk` con `d` y `e` borra y redimensiona particiones, y el kernel toma la tabla nueva sin reiniciar.
- Agrandar la partición no agranda el sistema de archivos. `resize2fs` amplía ext4 con el sistema montado.
- Antes de modificar la tabla de particiones conviene sacar una instantánea.

## Enlaces útiles y referencias

- Ayuda en Debian: `man fdisk`, `man resize2fs`, `man swapoff`, `man fstab`.
- Clase 12: [presentación](https://linux.idepba.com.ar/clase12.html).
- Siguiente práctica: [Laboratorio 11.2 - Agregar un disco](lab11.2.md).

-----

<p align="center">
<img src="../img/logos.footer.gray.webp">
</p>
