<?php

%%{
    machine atoi;
    access $this->;
    
	action see_neg   { $neg = true; }
	action add_digit { $res *= 10; $res += (fc - ord('0')); }

	main :=
		( '-'@see_neg | '+' )? ( digit @add_digit )+
		'\n'?
		;

}%%

class AtoI
{
    %% write data;
    public $cs;
    public $data;
    public function execute($data)
    {
        $this->data = $data;
        %% write init;
        $p = $neg = $res = 0;
        $pe = strlen($data);
        %% write exec;
        
        if ( $this->cs < static::$atoi_first_final )
            return FALSE;
        if ( $neg )
            $res *= -1;
        return $res;
    }
}

function _test($a,$b,$c)
{
    echo (assert($a->execute($b) === $c) ? "OK" : "FAIL").PHP_EOL;
}
$atoi = new AtoI();
_test($atoi, "7",                     7);
_test($atoi, "666",                 666);
_test($atoi, "-666",               -666);
_test($atoi, "+666",                666);
_test($atoi, "1234567890",   1234567890);
_test($atoi, "+1234567890",  1234567890);
// This will fail
_test($atoi, "+ 1234567890", 1234567890);
