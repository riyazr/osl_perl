#!/usr/bin/perl
use warnings;
use strict;
use Tie::File;
use Net::SMTP;
use LWP::UserAgent;
 

my $error_log  = 'Responser_errors.txt';
my $input_file = 'urls.txt';       
my $response_limit = 12; #In Seconds    

die "File $input_file is not exist\n" unless (-e $input_file);
my $localtime     = localtime;
our @errors;
my ($day,$month,$date,$hour,$year) = split /\s+/,scalar localtime;
my $output_file = 'report-'.$date.'.'.$month.'.'.$year.'.txt';
my (@all_addr) = ();
tie @all_addr, 'Tie::File', 
    $input_file or error("Cant open $input_file to read addresses");
if (-e $output_file) {
   open(OUT,">> $output_file") 
      or error("Cant open exist file $output_file for append");
} else {
   open(OUT,"> $output_file") 
      or error("Cant open new file $output_file for writting");
}

print OUT "\n+" .('-' x 84) . "+\n";
print OUT   "|", ' ' x 30,"Time: $hour",' ' x 40,"|\n";
print OUT   "|",' 'x 10,'HOST',' ' x 37,'STATUS',' ' x 7, 
                               "RESPONSE            |\n";
print OUT   "+" .('-' x 84) . "+\n";
for (0 .. $#all_addr) {
 chop $all_addr[$_] if ($all_addr[$_] =~ /\s+$/);
 next if ($all_addr[$_]  eq "");
 
   check_url($all_addr[$_]);    
}

my $err = join "\015\012",@errors;
my $err_num = scalar @errors;  
untie @all_addr or error("Unable to close file $input_file");
close OUT or error("Unable to close file $output_file");
print "\nProcess FINISH\n";

sub check_url {  # subroutine who check given URL
    my $target = $_[0];
        my $ua = LWP::UserAgent->new;
        $ua->agent("$0/0.1 " . $ua->agent);
        my $req = HTTP::Request->new(GET => "$target");
        $req->header('Accept' => 'text/html');          
        # send request
        my $start = time;      
        my $res = $ua->request($req);
        # check the outcome
        if ($res->is_success) {
        
          my $time = time;     
          my $out_format;
          $time = ($time - $start); 
          if ($response_limit && ($response_limit <= $time)) {
             push(@errors, "Slow response from $target\: $time seconds");
             $out_format = sprintf "| %-50.50s %-10s %-20s |\n", 
                      $target, "SLOW", "Response $time seconds";
          } else {
             $out_format = sprintf "| %-50.50s %-10s %-20s |\n", 
                  $target, "ACCESSED", "Response $time seconds";
          }
          print OUT $out_format; 
          print $out_format;     
        } else { 
          my $out_format = sprintf "| %-50.50s %-10s %-20s |\n", 
                                          $target, "DOWN", " N/A";
          push(@errors, "$target is DOWN." . $res->status_line) 
                           or error("Cannot push error for DOWN");
          print OUT $out_format; 
          print $out_format;     
    }
}
sub error {      
  my $error_msg = shift;
  open ERR,">> $error_log" 
       or die "Cannot open log file $error_log : $!\n";
  print ERR "$localtime\: $error_msg : $!\n";
  close ERR or die "Cannot close log file $error_log : $!\n";
}