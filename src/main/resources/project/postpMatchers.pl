push (@::gMatchers,
  {
   id =>        "error",
   pattern =>          q/(Error:.+|Fatal\s.+|fatal\s.+)/,
   action =>           q{

              my $description = "$1";
              setProperty("summary", $description . "\n");
    
   },
  },
);

