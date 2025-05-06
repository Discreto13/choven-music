#!/bin/sh

if [ $# -lt 1 ]; then
  echo "Usage: $0 <dir or file to scan>"
  exit 1
fi

INPUT_PATH="$1"

# Формуємо список файлів
if [ -d "$INPUT_PATH" ]; then
  files=("$INPUT_PATH"/*.mp3)
elif [ -f "$INPUT_PATH" ]; then
  files=("$INPUT_PATH")
else
  echo "❌ Помилка: $INPUT_PATH не знайдено"
  exit 1
fi

total=${#files[@]}
count=0

for file in "${files[@]}"; do
  count=$((count + 1))
  percent=$((count * 100 / total))
  echo "$percent% [$count/$total] Обробляю: $file"

  # Перевіряємо тип файлу, перекодовуємо за необхідності
  file_type=$(ffprobe -v error -show_entries format=format_name -of default=nw=1:nk=1 "$file")
  if [[ "$file_type" != *"mp3"* ]]; then
      echo "🔄 Файл не MP3, перекодовую: $file"
      tmp_fixed="${file%.mp3}-fixed.mp3"
      if ffmpeg -y -i "$file" -codec:a libmp3lame -qscale:a 2 "$tmp_fixed" &> /dev/null; then
          mv "$tmp_fixed" "$file"
          echo "✅ Перекодування завершено: $file"
      else
          echo "❌ Помилка перекодування: $file"
          continue
      fi
  fi

  filename=$(basename "$file" .mp3)
  artist=$(echo "$filename" | awk -F ' - ' '{print $1}')
  title=$(echo "$filename" | awk -F ' - ' '{print $2}')

  if [ -z "$artist" ] || [ -z "$title" ]; then
    echo "⚠️  Пропускаю. Назва файлу не задовольняє шаблон 'Автор - Трек': $file"
    continue
  fi

  # Коригування тегів (метаданих)
  tmp_file="${file%.mp3}-tmp.mp3"
  if ffmpeg -y -i "$file" \
    -map_metadata -1 \
    -metadata artist="$artist" \
    -metadata title="$title" \
    -c copy "$tmp_file" &> /dev/null; then

	mv "$tmp_file" "$file"
    echo "✅ Змінено: Artist='$artist', Title='$title'"
  else
    echo "❌ ПОМИЛКА: Не вдалося змінити теги для $file"
	[ -f "$tmp_file" ] && rm "$tmp_file"
  fi
done

echo "✨ Готово!"
