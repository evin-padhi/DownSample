version 1.0

workflow DownsampleBam {
  input {
    File input_bam
    File input_bai

    Int target_reads
    Int seed = 42
  }

  call Downsample {
    input:
      input_bam = input_bam,
      input_bai = input_bai,
      target_reads = target_reads,
      seed = seed
  }

  output {
    File bam = Downsample.downsampled_bam
    File bai = Downsample.downsampled_bai
  }
}

task Downsample {
  input {
    File input_bam
    File input_bai

    Int target_reads
    Int seed
  }

  command <<<
    set -euo pipefail

    TOTAL_READS=$(samtools view -c ~{input_bam})

    echo "Total reads: ${TOTAL_READS}"

    FRACTION=$(python3 -c "
total=${TOTAL_READS}
target=~{target_reads}
print(min(1.0, target/total))
")

    echo "Sampling fraction: ${FRACTION}"

    samtools view \
      -@ 8 \
      -bs ~{seed}.${FRACTION#0.} \
      ~{input_bam} \
    | samtools sort -@ 8 -o downsampled.bam

    samtools index downsampled.bam
  >>>

  runtime {
    docker: "biocontainers/samtools:v1.9-4-deb_cv1"
    memory: "16G"
    cpu: 8
    disks: "local-disk 200 SSD"
  }

  output {
    File downsampled_bam = "downsampled.bam"
    File downsampled_bai = "downsampled.bam.bai"
  }
}
