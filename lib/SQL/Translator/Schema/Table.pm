package SQL::Translator::Schema::Table;

# ----------------------------------------------------------------------
# $Id: Table.pm,v 1.3 2003-05-05 04:32:39 kycl4rk Exp $
# ----------------------------------------------------------------------
# Copyright (C) 2003 Ken Y. Clark <kclark@cpan.org>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; version 2.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
# 02111-1307  USA
# -------------------------------------------------------------------

=pod

=head1 NAME

SQL::Translator::Schema::Table - SQL::Translator table object

=head1 SYNOPSIS

  use SQL::Translator::Schema::Table;
  my $table = SQL::Translator::Schema::Table->new( name => 'foo' );

=head1 DESCSIPTION

C<SQL::Translator::Schema::Table> is the table object.

=head1 METHODS

=cut

use strict;
use Class::Base;
use SQL::Translator::Schema::Constants;
use SQL::Translator::Schema::Constraint;
use SQL::Translator::Schema::Field;
use SQL::Translator::Schema::Index;

use base 'Class::Base';
use vars qw( $VERSION $FIELD_ORDER );

$VERSION = 1.00;

# ----------------------------------------------------------------------
sub init {

=pod

=head2 new

Object constructor.

  my $table  =  SQL::Translator::Schema::Table->new( 
      schema => $schema,
      name   => 'foo',
  );

=cut

    my ( $self, $config ) = @_;
    
    for my $arg ( qw[ schema name ] ) {
        next unless defined $config->{ $arg };
        $self->$arg( $config->{ $arg } ) or return;
    }

    return $self;
}

# ----------------------------------------------------------------------
sub name {

=pod

=head2 name

Get or set the table's name.

If provided an argument, checks the schema object for a table of 
that name and disallows the change if one exists.

  my $table_name = $table->name('foo');

=cut

    my $self = shift;

    if ( my $arg = shift ) {
        if ( my $schema = $self->schema ) {
            return $self->error( qq[Can't use table name "$arg": table exists] )
                if $schema->get_table( $arg );
        }
        $self->{'name'} = $arg;
    }

    return $self->{'name'} || '';
}

# ----------------------------------------------------------------------
sub add_constraint {

=pod

=head2 add_constraint

Add a constraint to the table.  Returns the newly created 
C<SQL::Translator::Schema::Constraint> object.

  my $constraint1 = $table->add_constraint(
      name        => 'pk',
      type        => PRIMARY_KEY,
      fields      => [ 'foo_id' ],
  );

  my $constraint2 = SQL::Translator::Schema::Constraint->new( name => 'uniq' );
  $constraint2    = $table->add_constraint( $constraint );

=cut

    my $self             = shift;
    my $constraint_class = 'SQL::Translator::Schema::Constraint';
    my $constraint;

    if ( UNIVERSAL::isa( $_[0], $constraint_class ) ) {
        $constraint = shift;
        $constraint->table( $self );
    }
    else {
        my %args = @_;
        $args{'table'} = $self;
        $constraint = $constraint_class->new( \%args ) or 
            return $self->error( $constraint_class->error );
    }

    push @{ $self->{'constraints'} }, $constraint;
    return $constraint;
}

# ----------------------------------------------------------------------
sub add_index {

=pod

=head2 add_index

Add an index to the table.  Returns the newly created
C<SQL::Translator::Schema::Index> object.

  my $index1 = $table->add_index(
      name   => 'name',
      fields => [ 'name' ],
      type   => 'normal',
  );

  my $index2 = SQL::Translator::Schema::Index->new( name => 'id' );
  $index2    = $table->add_index( $index );

=cut

    my $self        = shift;
    my $index_class = 'SQL::Translator::Schema::Index';
    my $index;

    if ( UNIVERSAL::isa( $_[0], $index_class ) ) {
        $index = shift;
        $index->table( $self );
    }
    else {
        my %args = @_;
        $args{'table'} = $self;
        $index = $index_class->new( \%args ) or return 
            $self->error( $index_class->error );
    }

    push @{ $self->{'indices'} }, $index;
    return $index;
}

# ----------------------------------------------------------------------
sub add_field {

=pod

=head2 add_field

Add an field to the table.  Returns the newly created
C<SQL::Translator::Schema::Field> object.  The "name" parameter is 
required.  If you try to create a field with the same name as an 
existing field, you will get an error and the field will not be created.

  my $field1    =  $table->add_field(
      name      => 'foo_id',
      data_type => 'integer',
      size      => 11,
  );

  my $field2 =  SQL::Translator::Schema::Field->new( 
      name   => 'name', 
      table  => $table,
  );
  $field2    = $table->add_field( $field2 ) or die $table->error;

=cut

    my $self  = shift;
    my $field_class = 'SQL::Translator::Schema::Field';
    my $field;

    if ( UNIVERSAL::isa( $_[0], $field_class ) ) {
        $field = shift;
        $field->table( $self );
    }
    else {
        my %args = @_;
        $args{'table'} = $self;
        $field = $field_class->new( \%args ) or return 
            $self->error( $field_class->error );
    }

    my $field_name = $field->name or return $self->error('No name');

    if ( exists $self->{'fields'}{ $field_name } ) { 
        return $self->error(qq[Can't create field: "$field_name" exists]);
    }
    else {
        $self->{'fields'}{ $field_name } = $field;
        $self->{'fields'}{ $field_name }{'order'} = ++$FIELD_ORDER;
    }

    return $field;
}

# ----------------------------------------------------------------------
sub get_constraints {

=pod

=head2 get_constraints

Returns all the constraint objects as an array or array reference.

  my @constraints = $table->get_constraints;

=cut

    my $self = shift;

    if ( ref $self->{'constraints'} ) {
        return wantarray 
            ? @{ $self->{'constraints'} } : $self->{'constraints'};
    }
    else {
        $self->error('No constraints');
        return wantarray ? () : undef;
    }
}

# ----------------------------------------------------------------------
sub get_indices {

=pod

=head2 get_indices

Returns all the index objects as an array or array reference.

  my @indices = $table->get_indices;

=cut

    my $self = shift;

    if ( ref $self->{'indices'} ) {
        return wantarray 
            ? @{ $self->{'indices'} } 
            : $self->{'indices'};
    }
    else {
        $self->error('No indices');
        return wantarray ? () : undef;
    }
}

# ----------------------------------------------------------------------
sub get_field {

=pod

=head2 get_field

Returns a field by the name provided.

  my $field = $table->get_field('foo');

=cut

    my $self       = shift;
    my $field_name = shift or return $self->error('No field name');
    return $self->error( qq[Field "$field_name" does not exist] ) unless
        exists $self->{'fields'}{ $field_name };
    return $self->{'fields'}{ $field_name };
}

# ----------------------------------------------------------------------
sub get_fields {

=pod

=head2 get_fields

Returns all the field objects as an array or array reference.

  my @fields = $table->get_fields;

=cut

    my $self = shift;
    my @fields = 
        sort { $a->{'order'} <=> $b->{'order'} }
        values %{ $self->{'fields'} || {} };

    if ( @fields ) {
        return wantarray ? @fields : \@fields;
    }
    else {
        $self->error('No fields');
        return wantarray ? () : undef;
    }
}

# ----------------------------------------------------------------------
sub is_valid {

=pod

=head2 is_valid

Determine whether the view is valid or not.

  my $ok = $view->is_valid;

=cut

    my $self = shift;
    return $self->error('No name')   unless $self->name;
    return $self->error('No fields') unless $self->get_fields;

    for my $object ( 
        $self->get_fields, $self->get_indices, $self->get_constraints 
    ) {
        return $object->error unless $object->is_valid;
    }

    return 1;
}

# ----------------------------------------------------------------------
sub schema {

=pod

=head2 schema

Get or set the table's schema object.

  my $schema = $table->schema;

=cut

    my $self = shift;
    if ( my $arg = shift ) {
        return $self->error('Not a schema object') unless
            UNIVERSAL::isa( $arg, 'SQL::Translator::Schema' );
        $self->{'schema'} = $arg;
    }

    return $self->{'schema'};
}

# ----------------------------------------------------------------------
sub primary_key {

=pod

=head2 options

Gets or sets the table's primary key(s).  Takes one or more field names 
(as a string, list or arrayref) and returns an array or arrayref.

  $table->primary_key('id');
  $table->primary_key(['id']);
  $table->primary_key(['id','name']);
  $table->primary_key('id,name');
  $table->primary_key(qw[ id name ]);

  my $pk = $table->primary_key;

=cut

    my $self = shift;
    my $fields = UNIVERSAL::isa( $_[0], 'ARRAY' ) 
        ? shift : [ map { s/^\s+|\s+$//g; $_ } map { split /,/ } @_ ];

    if ( @$fields ) {
        for my $f ( @$fields ) {
            return $self->error(qq[Invalid field "$f"]) unless 
                $self->get_field($f);
        }

        my $has_pk;
        for my $c ( $self->get_constraints ) {
            if ( $c->type eq PRIMARY_KEY ) {
                $has_pk = 1;
                $c->fields( @{ $c->fields }, @$fields );
            } 
        }

        unless ( $has_pk ) {
            $self->add_constraint(
                type   => PRIMARY_KEY,
                fields => $fields,
            );
        }
    }

    for my $c ( $self->get_constraints ) {
        return $c if $c->type eq PRIMARY_KEY;
    }

    return $self->error('No primary key');
}

# ----------------------------------------------------------------------
sub options {

=pod

=head2 options

Get or set the table's options (e.g., table types for MySQL).  Returns
an array or array reference.

  my @options = $table->options;

=cut

    my $self    = shift;
    my $options = UNIVERSAL::isa( $_[0], 'ARRAY' ) 
        ? shift : [ map { s/^\s+|\s+$//g; $_ } map { split /,/ } @_ ];

    push @{ $self->{'options'} }, @$options;

    if ( ref $self->{'options'} ) {
        return wantarray ? @{ $self->{'options'} || [] } : $self->{'options'};
    }
    else {
        return wantarray ? () : [];
    }
}

1;

# ----------------------------------------------------------------------

=pod

=head1 AUTHOR

Ken Y. Clark E<lt>kclark@cpan.orgE<gt>

=cut