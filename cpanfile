requires 'LWP::UserAgent', '>= 6.0';
requires 'HTML::TreeBuilder', '>= 5.0';
requires 'JSON', '>= 4.0';
requires 'DBI', '>= 1.643';
requires 'DBD::Pg', '>= 3.0';

on 'test' => sub {
    requires 'Test::More', '>= 1.302';
    requires 'Test::Exception', '>= 0.43';
};

on 'develop' => sub {
    requires 'Perl::Critic', '>= 1.140';
    requires 'Perl::Tidy', '>= 20220613';
};
