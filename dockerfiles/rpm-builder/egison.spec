Name:       egison
Summary:    Egison is a purely functional programming language with non-linear pattern-matching against non-free data types.
Version:    @@@VERSION@@@
Group:      Applications
License:    MIT
Release:    %(date '+%'s)
URL:        https://egison.org
Source:     https://github.com/greymd/rpm-egison/archive/egison_linux_%{architecture}_%{version}.tar.gz
BuildArch:  %(uname -m)
Vendor:     Egi, Satoshi <egison at egison dot org>
Provides:   egison

BuildRoot: %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)

%description
Egison is a functional programming language featuring its expressive pattern-matching facility. Egison allows users to define efficient and expressive pattern-matching methods for arbitrary user-defined data types including non-free data types such as lists, multisets, sets, trees, graphs, and mathematical expressions. This is the repository of the interpreter of Egison.
For more information, visit [our website](https://egison.org).

%prep
%setup

%install
install -d -m 0755 %{buildroot}%{_bindir}
%{__cp} -a bin/* %{buildroot}%{_bindir}/
install -d -m 0755 %{buildroot}%{_libdir}
%{__cp} -a lib/* %{buildroot}%{_libdir}/

%files
%defattr(0644, root, root, 0755)
%doc README.md THANKS.md
%license LICENSE
%attr(0755, root, root) %{_bindir}/*

%clean
%{__rm} -rf %{buildroot}
