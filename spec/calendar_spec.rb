require 'spec_helper'

module VPS
  module Plugins
    module Calendar
      describe Person, '#format_name' do

        it 'formats <e-mailaddress>' do
          name = Person.format_name('john.doe@example.com')
          expect(name).to eq('John Doe')
        end

        it 'formats <last name(s)> <middle name(s)>, <initials> (<first name(s)>)' do
          name = Person.format_name('Doe from the, J (John)')
          expect(name).to eq('John from the Doe')
        end

        it 'formats <middle name> <last name(s)> <middle name>, <initials> (<first name(s)>)' do
          name = Person.format_name('from Doe the, J (John)')
          expect(name).to eq('John from the Doe')
        end

        it 'formats <middle name(s)> <last name(s)>, <first name(s)>' do
          name = Person.format_name('from the Doe, John')
          expect(name).to eq('John from the Doe')
        end

        it 'formats <initials> <middle name(s)> <last name(s)> (<first name(s)>) (<e-mail address>)' do
          name = Person.format_name('J from the Doe (John) (john.doe@example.com)')
          expect(name).to eq('John from the Doe')
        end

        it 'formats <last name(s)>, <initials> (<first name(s)>) (<e-mail address>)' do
          name = Person.format_name('Doe, J (John) (john.doe@example.com)')
          expect(name).to eq('John Doe')
        end

        it 'formats \'anything\' as anything' do
          name = Person.format_name('\'Doe, J (John) (john.doe@example.com)\'')
          expect(name).to eq('John Doe')
        end
      end
    end
  end
end