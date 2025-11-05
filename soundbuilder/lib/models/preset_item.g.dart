// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preset_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PresetItemAdapter extends TypeAdapter<PresetItem> {
  @override
  final int typeId = 1;

  @override
  PresetItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PresetItem(
      soundName: fields[0] as String,
      volume: fields[1] as double,
      speed: fields[2] as double,
      pitch: fields[3] as double,
      pan: fields[4] as double,
    );
  }

  @override
  void write(BinaryWriter writer, PresetItem obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.soundName)
      ..writeByte(1)
      ..write(obj.volume)
      ..writeByte(2)
      ..write(obj.speed)
      ..writeByte(3)
      ..write(obj.pitch)
      ..writeByte(4)
      ..write(obj.pan)
      ..writeByte(5)
      ..write(obj.offsetMs);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresetItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
