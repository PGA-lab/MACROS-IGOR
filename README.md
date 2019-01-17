MACROS-IGOR
===========

Descargar GIT desde https://git-scm.com/.

Instalar con las opciones default hasta que aparezca la IMAGEN

Seleccionar como en IMAGEN (ELEGIR WINDOWS DEFAULT CONSOLE WINDOW): 

<img src=https://github.com/mjmoglie/MACROS-IGOR/blob/master/IMAGENES/3f03e277-1d72-407b-869a-0c7f22fcfb85.jpg width="600">

## PARA INICIAR REPOSITORIO LOCAL:

Ejecutar .cmd

Cambiar a directorio donde se almacenan los macros

`git init`

### SI NO SE TIENE UNA CARPETA DE MACROS PREVIA:

`git remote add origin https://github.com/mjmoglie/MACROS-IGOR`

`git pull https://github.com/mjmoglie/MACROS-IGOR`

### SI SE TIENE UNA CARPETA DE MACROS PREVIA:

`git remote add origin https://github.com/mjmoglie/MACROS-IGOR`

`git fetch origin master`

`git merge origin/master`

## ACTUALIZAR FILES (DESCARGA)

Ejecutar .cmd

Cambiar a directorio donde se almacenan los macros

`git fetch origin master`
`git merge origin/master`

## ACTUALIZAR FILES (SUBIDA)

Ejecutar .cmd

Cambiar a directorio donde se almacenan los macros

`git status`

`git add -u ./`

`git commit -a -m "MENSAJE A GUSTO"`

`git push`
