#!/bin/bash

NEW_WIDTH=0
NEW_HEIGHT=0
resize_flags="--resize_width=$NEW_WIDTH --resize_height=$NEW_HEIGHT "
# uncomment below to disable resizing
resize_flags=""

home=$(pwd)
source_image_root="$1"
dest_lmdb="$1_lmdb"
dest_mean_image="$1_mean.binaryproto"
if [ -z "$CAFFE_ROOT" ]
then
  caffe_root="/home/rohit/caffe"
fi

files_list="$home/$source_image_root/files_list.txt"
label_map="$home/$source_image_root/label_map.txt"
if [ -f "$files_list" ];
then
  rm "$files_list"
fi
if [ -f "$label_map" ];
then
  rm "$label_map"
fi
echo "Files list: $files_list"

cd "$source_image_root"

# numerical labels are assigned
label_count=0;
for folder in */;
do
  echo "Enumerating folder $folder";
  cd "$home"; cd "$source_image_root/$folder";
  non_empty_folder=0;
  for file in $(ls *.jpg);
  do
    echo "${folder}${file} $label_count" >> "$files_list";
    non_empty_folder=1;
  done
  if (( non_empty_folder ));
  then
    echo "$label_count $(basename ${folder})" >> "$label_map";
    (( label_count++ ))
  fi
done

cd "$home"
echo "Building LMDB in $dest_lmdb"
if [ -d "$dest_lmdb" ]
then
  rm -rf "$dest_lmdb"
fi

GLOG_logtostderr=1 $caffe_root/build/tools/convert_imageset --shuffle --gray $resize_flags "$source_image_root/" "$files_list" "$dest_lmdb"
echo "LMDB created in $dest_lmdb"

$caffe_root/build/tools/compute_image_mean "$dest_lmdb" "$dest_mean_image"
echo "Image mean saved in $dest_mean_image"

