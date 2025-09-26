#!/bin/bash
if [ -t 0 ]; then
  echo "Cantidad inadecuada de entradas."
  echo "Uso: cat liv2019.csv | permisos.sh"
  exit 1
fi
awk -F';' '
BEGIN{
  OFS=""; col=-1; sum=0; cnt=0;
}
NR==1{
  for(i=1;i<=NF;i++){
    h=$i; gsub(/"/,"",h); hl=tolower(h);
    gsub(/[[:space:]]+/," ",hl);
    if (hl ~ /permiso 2019/){ col=i; break; }
  }
  next;
}
{
  if (col<0) next;
  v=$col;
  gsub(/"/,"",v);
  gsub(/[[:space:]]/,"",v);
  gsub(/\./,"",v);      # quitar miles por si existieran
  gsub(/,/,".",v);      # normalizar decimal
  if (v ~ /^[0-9]+([.][0-9]+)?$/){
    val=v+0;
    if (cnt==0 || val<min) min=val;
    if (cnt==0 || val>max) max=val;
    sum+=val; cnt++;
  }
}
END{
  if (col<0){
    print "No se encontro la columna PERMISO 2019 en el encabezado.\n";
    exit 1;
  }
  if (cnt==0){
    print "No se encontraron datos numericos en PERMISO 2019.\n";
    exit 1;
  }
  avg=sum/cnt;
  printf "Promedio permisos 2019: %.3f\nMinimo: %.3f\nMaximo: %.3f\n\n", avg, min, max;
}' 
