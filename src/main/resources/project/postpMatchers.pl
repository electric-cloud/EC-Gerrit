push (@::gMatchers,
  {
   id =>        "error",
   pattern =>          q/(Error:.+|Fatal\s.+|fatal\s.+)/,
   action =>           q{

              my $description = "$1";
              setProperty("summary", $description . "\n");
   },
  },
  {
   id =>        "skippingScan",
   pattern =>          q/(Skipping\sscan\sfor\sconfiguration\s.+)/,
   action =>           q{

            my $description = "$1";
            setProperty("summary", $description . "\n");

  },
 },
 {
   id =>        "completedScan",
   pattern =>          q/(Completed\sscan\sfor\sconfiguration\s.+)/,
   action =>           q{

            my $description = "$1";
            setProperty("summary", $description . "\n");

   },
 },
 {
   id =>        "allCompletedScan",
   pattern =>          q/(Scan\scompleted\sfor\sall\sconfigurations)/,
   action =>           q{

            my $description = "$1";
            setProperty("summary", $description . "\n");

   },
 },
);

