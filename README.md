MACROS-IGOR
===========

1. Descargar GIT desde https://git-scm.com/.

2. Instalar con las opciones default hasta que aparezca la __IMAGEN__

Seleccionar como en __IMAGEN__ (ELEGIR WINDOWS DEFAULT CONSOLE WINDOW): 

<img src=https://github.com/mjmoglie/MACROS-IGOR/blob/master/IMAGENES/3f03e277-1d72-407b-869a-0c7f22fcfb85.jpg width="600">

***

## PARA INICIAR REPOSITORIO LOCAL:

1. Ejecutar .cmd

2. Cambiar a directorio donde se almacenan los macros

`git init`

### - SI NO SE TIENE UNA CARPETA DE MACROS PREVIA:

`git remote add origin https://github.com/mjmoglie/MACROS-IGOR`

`git pull https://github.com/mjmoglie/MACROS-IGOR`

### + SI SE TIENE UNA CARPETA DE MACROS PREVIA:

**ir a ACTUALIZAR FILES (SUBIDA) y realizar todos los pasos excepto** `git push`
(esto hace que cuando se bajen los macros que están en el repositorio remoto *github* estos se mergeen con los locales)

`git remote add origin https://github.com/mjmoglie/MACROS-IGOR`

`git fetch origin master`

`git merge origin/master`

***

## ACTUALIZAR FILES (DESCARGA)

1. Ejecutar .cmd

2. Cambiar a directorio donde se almacenan los macros

`cd C:\sarasa`

3. Checkear que esté bien configurado el repo remoto
 `git remote -v`
 
 tiene que figurar:
```origin  https://github.com/mjmoglie/MACROS-IGOR (fetch)

origin  https://github.com/mjmoglie/MACROS-IGOR (push)
```

`git fetch origin master`

`git merge origin/master`

***

## ACTUALIZAR FILES (SUBIDA)

1. Ejecutar .cmd

2. Cambiar a directorio donde se almacenan los macros

`cd C:\sarasa`

`git status`

`git add -u ./`

`git commit -a -m "MENSAJE A GUSTO"`

`git push`
