#!/bin/bash

# Функция для обработки одной строки TSV
process_line() {
  # Аргументы: id, start, end, genome_dir, output_dir
  local id="$1"
  local start="$2"
  local end="$3"
  local genome_dir="$4"
  local output_dir="$5"

  echo "$id"
  # Поиск файла .fna.gz, содержащего заголовок с указанным ID
  file=$(find "$genome_dir" -type f -name "*.fna.gz" -exec zgrep -l "$id" {} \; | head -n 1)
  if [ -z "$file" ]; then
    echo "Ошибка: файл не найден для ID: $id" >&2
    return 1
  fi
  echo "файл найден для ID: $id"
  
  # Извлечение точного имени заголовка из файла.
  # Ищем строку, начинающуюся с ">" и содержащую $id.
  header=$(zgrep -m 1 "^>.*$id" "$file" | sed 's/^>//' | awk '{print $1}')
  if [ -z "$header" ]; then
    echo "Ошибка: заголовок не найден для ID: $id в файле $file" >&2
    return 1
  fi

  # Формирование региона для seqkit в формате start:end.

  if [ -z "$header" ]; then
    echo "Ошибка: заголовок не найден для ID: $id в файле $file" >&2
    return 1
  fi
  
  if [ "$start" -gt "$end" ]; then
    
    region="$end:$start"
    #seqkit seq -r "$file" 
    seqkit seq --complement "$file" | seqkit subseq --chr "$header" -r "$region" | seqkit seq -r > "$output_dir/${id}_${end}_${start}.fasta"
  else
    region="$start:$end"
    seqkit subseq --chr "$header" -r "$region" "$file" > "$output_dir/${id}_${start}_${end}.fasta"
  fi
  
  #region="$start:$end"

  #seqkit subseq --chr "$header" -r "$region" "$file" > "$output_dir/${id}_${start}_${end}.fasta"


  if [ $? -ne 0 ]; then
    echo "Ошибка: seqkit не смог обработать ID: $id" >&2
    return 1
  fi
}

# Экспортируем функцию для использования в xargs
export -f process_line

# Парсинг входных параметров.
# Добавлена опция -t для указания числа потоков.
while getopts "i:g:o:t:" opt; do
  case $opt in
    i) tsv_file="$OPTARG" ;;
    g) genome_dir="$OPTARG" ;;
    o) output_dir="$OPTARG" ;;
    t) threads="$OPTARG" ;;
    \?) echo "Неверный параметр: -$OPTARG" >&2; exit 1 ;;
  esac
done

# Проверка наличия обязательных параметров
if [ -z "$tsv_file" ] || [ -z "$genome_dir" ] || [ -z "$output_dir" ]; then
  echo "Использование: $0 -i <tsv_file> -g <genome_dir> -o <output_dir> [-t <threads>]" >&2
  exit 1
fi

# Если количество потоков не задано, устанавливаем значение по умолчанию (4)
if [ -z "$threads" ]; then
   threads=4
fi

# Проверка существования входного файла и директории
if [ ! -f "$tsv_file" ]; then
  echo "Ошибка: файл $tsv_file не существует" >&2
  exit 1
fi
if [ ! -d "$genome_dir" ]; then
  echo "Ошибка: директория $genome_dir не существует" >&2
  exit 1
fi

# Создание выходной директории, если она не существует
mkdir -p "$output_dir"
if [ $? -ne 0 ]; then
  echo "Ошибка: не удалось создать директорию $output_dir" >&2
  exit 1
fi

# Чтение TSV файла и распараллеливание обработки строк с помощью xargs.
# Файл TSV должен быть разделён табами и содержать 3 колонки: id, start, end.
# Опция -d '\n' используется для разделения по строкам, -I {} подставляет всю строку,
# а -P "$threads" задаёт число параллельных процессов.
cat "$tsv_file" | xargs -d '\n' -I {} -P "$threads" bash -c '
  # Удаляем символы возврата каретки для корректного чтения координат
  line=$(echo "{}" | tr -d "\r")
  read id start end <<< "$line"
  process_line "$id" "$start" "$end" "$0" "$1"
' "$genome_dir" "$output_dir"

exit 0
