#!/usr/bin/env nextflow

methods = ['prot','dna','rna']

params.reads = "$baseDir/data/ggal/*_{1,2}.fq"
params.transcriptome = "$baseDir/data/ggal/transcriptome.fa"
params.multiqc = "$baseDir/multiqc"


process foo {
  input:
  val x from methods

  output:
  val x into receiver

  """
  echo $x > file
  """

}

receiver.view { "Received: $it" }




