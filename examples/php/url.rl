<?php
%%{
    machine url;
	access $this->;
	action mark      { $mark = $p;                                }
	action str_start { $buffer = "";                             }
	action str_char  { $buffer .= chr(fc);                      }
	action str_lower { $buffer .= chr(fc + 0x20);               }
	action hex_hi    { $hex = hexdec(fc) * 16;                   }
	action hex_lo    { $buffer .= $hex + hexdec(fc);             }
	action scheme    { $this->scheme = $buffer;                  }
	action authority { $this->authority = substr($url,$mark,$p-$mark); }
	action path      { $this->path = $buffer;                    }
	action query     { $this->query = substr($url,$mark,$p-$mark);     }
	action fragment  { $this->fragment = $buffer;                }

	# # do this instead if you *actually* use URNs (lol)
	# action authority { url.Authority = string(data[mark:p]) }

	# define what a single character is allowed to be
	toxic     = ( cntrl | 127 ) ;
	scary     = ( toxic | " " | "\"" | "#" | "%" | "<" | ">" ) ;
	schmchars = ( lower | digit | "+" | "-" | "." ) ;
	authchars = any -- ( scary | "/" | "?" | "#" ) ;
	pathchars = any -- ( scary | "?" | "#" ) ;
	querchars = any -- ( scary | "#" ) ;
	fragchars = any -- ( scary ) ;

	# define how characters trigger actions
	escape    = "%" xdigit xdigit ;
	unescape  = "%" ( xdigit @hex_hi ) ( xdigit @hex_lo ) ;
	schmfirst = ( upper @str_lower ) | ( lower @str_char ) ;
	schmchar  = ( upper @str_lower ) | ( schmchars @str_char ) ;
	authchar  = escape | authchars ;
	pathchar  = unescape | ( pathchars @str_char ) ;
	querchar  = escape | querchars ;
	fragchar  = unescape | ( fragchars @str_char ) ;

	# define multi-character patterns
	scheme    = ( schmfirst schmchar* ) >str_start %scheme ;
	authority = authchar+ >mark %authority ;
	path      = ( ( "/" @str_char ) pathchar* ) >str_start %path ;
	query     = "?" ( querchar* >mark %query ) ;
	fragment  = "#" ( fragchar* >str_start %fragment ) ;
	url       = scheme ":" "//"? authority path? query? fragment?
		      | scheme ":" "//" authority? path? query? fragment?
		      ;

	main := url;

}%%

class Url {
    %% write data;
    private $cs;
	public $scheme;    // http, sip, file, etc. (never blank, always lowercase)
	public $authority; // user:pass@host:port
	public $path;      // stuff starting with '/'
	public $query;     // stuff after '?' (NOT UNESCAPED)
	public $fragment;  // stuff after '#'
    public function parse($url)
    {
        $this->cs = $mark = 
		$p = $amt = $hex = 0;
        $pe = $eof = strlen($url);
        $this->scheme = $this->authority = 
		$this->params = $this->path = 
		$this->query = $this->fragment = $buffer = "";
        $this->data = $url;
        
        %% write init;
        %% write exec;
        
    	if ( $this->cs < static::$url_first_final )
        {
    		if ($p == $pe)
                throw new Exception(spritnf('unexpected eof: %s', $url));
    		// else
    		// 	throw new Exception(sprintf('error in url at pos %d: %s',$p,$url));
    	}
        
        return $this;
    }
	public function __toString(){
		$str = $this->data . PHP_EOL;
		$params = array('scheme','authority','path','query','fragment');
		while($param = array_shift($params))
		{
			$val = $this->$param;
			if(!empty($val))
				$str .= sprintf(' - %-10s : %s'.PHP_EOL,$param,$val);
		}
		$str .= PHP_EOL;
		return $str;
	}
}

$urls = array(
	'http://user:pass@example.com:80;hello/lol.php?fun#omg',
	'GoPHeR://@example.com@:;/?#',
	'ldap://[2001:db8::7]/c=GB?objectClass/?one',
	'http://user@example.com',
	'http://品研发和研发管@☃.com:65000;%20',
	'https://example.com:80',
	'file:///etc/passwd',
	'file:///c:/WINDOWS/clock.avi',
	'file://hostname/path/to/the%20file.txt',
	'sip:example.com',
	'sip:example.com:5060',
	'mailto:ditto@pokémon.com',
	'sip:[dead:beef::666]:5060',
	'tel:+12126660420',
	'sip:bob%20barker:priceisright@[dead:beef::666]:5060;isup-oli=00/palfun.html?haha#omg',
	'http://www.google.com/search?%68l=en&safe=off&q=omfg&aq=f&aqi=g2g-s1g1g-s1g5&aql=&oq=&gs_rfai=',
);

$url = new Url();
while($str = array_shift($urls))
	print $url->parse($str);