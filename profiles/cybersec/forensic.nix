# A collection of tools used in cybersec forensics challenges
{ ... }:
{
    import = with profiles.cybersec.forensic; [
        audio
        disk
        files
        misc
        stego
    ]
}