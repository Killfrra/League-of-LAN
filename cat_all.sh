#!/bin/bash
printf '' > all_in_one.txt && find . -type f -name '*.gd' -exec cat {} >> all_in_one.txt \; -exec echo '' >> all_in_one.txt \;
#PLANTUML_LIMIT_SIZE=16384 plantuml classes.puml
