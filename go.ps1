./nuke.ps1
dub --compiler=ldc2 -- makemigrations
dub --compiler=ldc2 -- migrate
dub --compiler=ldc2 -- orm