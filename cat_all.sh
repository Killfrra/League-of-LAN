#!/bin/bash
printf '' > all_in_one.txt && find ./scripts ./entities -name '*.gd' -exec cat {} >> all_in_one.txt \; -exec echo '' >> all_in_one.txt \;
#PLANTUML_LIMIT_SIZE=16384 plantuml classes.puml
