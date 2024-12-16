# SSHD configuration
#---------------------------------------------------------------------------------------------------
{ args, ... }:
{
  services.openssh = {
    enable = true;
  };

  users.motd = ''
    -----------------------------------------------------------------------------------------
                                                 |
                      |                        .$$
                      $$.                     .$$$
                      $$$.                    $$$$
                      $$$$                    $$$$
     -===============-$$$$-==================-$$$$-=========- -high tech, low life -=======-
                      $$$$                    $$$$
                      $$$$  ....        ..    $$$$  #### ..    .,,,    ,,'$$        $$$$$'
        .4$$$$$$$$$$. $$####|$$$B.4BBBBBBB$##|$$$$|B.### $$$$$$$$$$$ii $$$$3$      $$$$$
        $$$$$$$$$$$$$ $$####|4$$$B|BBBBBBBB##|$$$$|#P    9$$$P$$$9$$$$ $$$#$$$    $$$$$
        $$$$    ####' $$#### '4$$$$     9BBB  $$$$ '$$$$ 0$$$  BB|$$$$ $$$#$$$$..$$$$$
        $$$$    ####  $$####   $$$$BBBBBBBBB  $$$$  $$$$ $$$$  $$|$$$$ $$$$ $$$$$$$$'
        $$$$    ####  $$####   $$$BBBBBBBBB'  $$$$  $$$$ $$$$  $$|$$$$ $$$$ '$$$$$$$
        $$$$    ###P  $$####   $$$B     $$$$  $$$$  $$$$ $$$$  $$|$$$E $$$$.$$$$$$$$$
        $$$$    ###..#$$#### .d$$$B     $$$$  $$$$  $$$$ $$$$  $$|$$$E3$$$$3$$$  $$$$$
    -==-$$$$$$$$$$$$$#######|B9$$'BBBBBBBBB$--$$$$--$$$$-$$$$--$$|$$$E3$$$|$$$-==-$$$$$-====-
     -=-'4$$$$$$$$$P-=-'####|BBP'9BVVVVVVVBV--$$$$--$$$'-VVVV--``'VVVV''$$$$$-====-$$$$$-==-
       -=======-4###########-==========-''''--$$$'--'-===============-.$$$$$-======-$$$$$.TM
                '##########P                  $$'  -phR0ze
                                              |

  '';
}
