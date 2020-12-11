#!/usr/bin/env nextflow
log.info "~~~ HowardJC's Pipeline ~~"
log.info "* reads:              ${params.reads}"
log.info "* outdir:             ${params.outdir}"
log.info "* Launch dir:         ${workflow.launchDir}"
log.info "* Work dir:           ${workflow.workDir}"
log.info "* Profile             ${workflow.profile ?: '-'}"
log.info "* Workflow container  ${workflow.container ?: '-'}"
log.info "* container engine    ${workflow.containerEngine?:'-'}"
log.info "* Nextflow run name   ${workflow.runName}"

Channel.fromFilePairs("$params.reads",flat:true).set{queryFile_ch}
Channel.fromPath("$params.transcriptome").set{Transcriptset}

process cutadapt{

    input:
    tuple val(sample_id), file(sample_file1), file(sample_file2) from queryFile_ch 


    output:
    set path("${sample_file1}"), path("${sample_file2}") into (queryFile_ch1,queryFile_ch2)

    script:
    // """
    // cutadapt -a AGATCGGAAGAGCACACGTCTGAACTCCAGTCA -A AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT ${sample_file1} ${sample_file2} | sponge | gzip 
    // """
    """
    cutadapt -a AGATCGGAAGAGCACACGTCTGAACTCCAGTCA -A AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT -o Clowned.fastq.gz -p Card.fastq.gz -z  ${sample_file1} ${sample_file2} 
    cutadapt -q 20,20 -o Clowned.fastq.gz ${sample_file1} 
    cutadapt -q 20,20 -o Card.fastq.gz ${sample_file2}

    """

}


process fastqc{


    input:
    path(queryFile) from queryFile_ch1.flatten()

    output: 
    path("fastqc_${queryFile}")  into fastqc_ch

    script:
    """
    mkdir fastqc_${queryFile}
    fastqc -o fastqc_${queryFile} -f fastq ${queryFile}
    """

}

process multimc{
    publishDir "${params.outdir}", mode: 'copy'
    input:
    path('Mea') from fastqc_ch.collect()

    output:
    path('multiqc_report.html')

    script:
    """
    multiqc ${Mea}
    """
    

}
process Annotation{

    cache 'lenient'

    
    input:
    path(Query) from Transcriptset
    
    output:
    path('hts') into Annotations

    script:
    """

    gunzip ${Query}/*.fna.gz || echo "Does not exist"
    gunzip ${Query}/*.gff.gz || echo "Does not exist"
    hisat2-build ${Query}/*.fna ${Query}/*.gff
    mkdir hts
    mv ${Query}/*.ht2 hts
    """


}

process Alignment{
    cache 'lenient'

    publishDir "${params.outdir}/Bams", mode: 'copy'
    Next=queryFile_ch2.flatten().branch {
        RunsOne: it =~ /.*[1]\..*/
        RunsTwo: it =~ /.*[2]\..*/}

    
    input:
    each Query from Annotations
    path(Runs1) from Next.RunsOne
    path(Runs2) from Next.RunsTwo


    
    output:
    path('Bams/*') into BAMfiles

    shell:
    '''
    #!/bin/sh
    echo !{Query}
    echo ----------------
    echo !{Runs1}
    echo ----------------

    Id=$(basename !{Runs1} | cut -f 1 -d "_")
    Basename=$(sudo basename !{Query}/*.gff.1.* .1.ht2)
    echo $Basename
    echo !{Query}/$Basename
    mkdir Bams
    HISAT2_INDEXES=!{Query}
    export HISAT2_INDEXES=!{Query}
    #hisat2 -x $Basename -1 !{Runs1} -2 !{Runs2} -S Sams/${Id}.sam
    hisat2 -x $Basename -1 !{Runs1} -2 !{Runs2} | samtools view -bS -  > Bams/${Id}.bam

    '''


}



process ReadQualityStatistics{

    publishDir "${params.outdir}/BamStatistics", mode:'copy'

    input:
    path(FlaggerQuery) from BAMfiles

    output:
    path("Statistics_${FlaggerQuery.baseName}")

    script:
    """
    
    samtools flagstat ${FlaggerQuery} > Statistics_${FlaggerQuery.baseName}
    """


}

workflow.onComplete{
    println("Complete")
}

