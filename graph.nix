{ pkgs, lib }:
{
  mkGraph = el: width: height:
  {
    inherit height width;
    data = genList (x: genList (y: el x y) height) width;
  }
}
