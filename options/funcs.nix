# Import all functions
#---------------------------------------------------------------------------------------------------
{ lib, ... }:
{
  boolToStr = x: if x then "true" else "false";
  boolToInt = x: if x then 1 else 0;
}
