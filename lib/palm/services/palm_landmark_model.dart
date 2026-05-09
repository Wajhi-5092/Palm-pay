/// Detached landmark model shared by Mediapipe engine implementations.
class PalmLm {
  const PalmLm(this.x, this.y, this.z);
  final double x;
  final double y;
  final double z;

  PalmLm operator -(PalmLm o) => PalmLm(x - o.x, y - o.y, z - o.z);

  PalmLm operator +(PalmLm o) => PalmLm(x + o.x, y + o.y, z + o.z);

  PalmLm operator *(double s) => PalmLm(x * s, y * s, z * s);
}
