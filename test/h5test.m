%{

    Copyright 2012 Tom Mullins
    Copyright 2015 Tom Mullins, Stefan Großhauser

    This file is part of hdf5oct.

    hdf5oct is free software: you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    hdf5oct is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public License
    along with hdf5oct.  If not, see <http://www.gnu.org/licenses/>.


%}

pkg load hdf5oct

disp("------------ test help strings: ----------------")
help h5read
help h5write
help h5readatt
help h5writeatt
help h5create

% for debugging:
%system (sprintf ("gnome-terminal --command 'gdb -p %d'", getpid ()), "async");

disp("------------ generate testdata: ----------------")

dims = [4, 8, 3, 2];

global d;
d = {(1:dims(1))'};
for k = 2:4
  i_dims = dims(1:k);
  d{k} = zeros(i_dims);
  for j = 1:k
    perm = i_dims;
    perm(j) = 1;
    M = 10^(j-1) * (1:i_dims(j))';
    M = permute(M, [2:j, 1, j+1:k]);
    d{k} += repmat(M, perm);
  end
end

function mat = hyperslab(mat, rank, start, count, stride, block)
  start = [start, ones(1, 4-rank)];
  count = [count, ones(1, 4-rank)];
  stride = [stride, ones(1, 4-rank)];
  block = [block, ones(1, 4-rank)];
  idx = {};
  for k = 1:4
    idx{k} = [];
    for b = 0:(block(k)-1)
      idx{k} = [idx{k}, (start(k)+b) : stride(k) : (count(k)*stride(k)-1+start(k)+b)];
    end
    idx{k} = sort(idx{k});
  end
  mat = mat(idx{1}, idx{2}, idx{3}, idx{4});
end

function check_slice(filename, rank, start=[], count=[], stride=[], block=[])
  global d;
  dataset = strcat('t', num2str(rank));
  if start
    if block
      data = h5read(filename, dataset, start, count, stride, block);
    else
      block = ones(1, rank);
      if stride
        data = h5read(filename, dataset, start, count, stride);
      else
        stride = ones(1, rank);
        data = h5read(filename, dataset, start, count);
      end
    end
    comp = hyperslab(d{rank}, rank, start, count, stride, block);
  else
    data = h5read(filename, dataset);
    if (rank == 0)
      comp = 0;
    else
      comp = d{rank};
    end
  end
  res = data == comp;
  while ~isscalar(res)
    res = all(res);
  end
  if res
    printf('Success\n');
  else
    printf('Failed\n');
  end
end

disp("------------ test functionality: ----------------")

disp("Test h5create and h5write hyperslabs...")
chunksize = [1 3 2];
h5create("test.h5","/created_dset1",[ Inf 3 2],'ChunkSize',chunksize)

k=0;
%h5write("test.h5","/created_dset1",reshape((1:prod(chunksize))*10**k,chunksize), [ 1+chunksize(1)*k, 1, 1], chunksize)
k = k+1;
start = [ 1+chunksize(1)*k, 1, 1];
h5write("test.h5","/created_dset1",reshape((1:prod(chunksize))*10**k,chunksize), start, chunksize)
k = k+1
start = [ 1+chunksize(1)*k, 1, 1];
h5write("test.h5","/created_dset1",reshape((1:prod(chunksize))*10**k,chunksize), start, chunksize)
%%%%%%%%
h5create("test.h5","/created_dset_single",[ 2 3 4],'Datatype','single')
%%%%%%%%
h5create("test.h5","/created_dset_inf1",[ Inf Inf 4],'Datatype','uint16', 'ChunkSize', [10 2 4])
%%%%%%%%
chunksize = [2 3 2];
h5create("test.h5","created_dset_inf2",[ 2 3 Inf],'Datatype','uint32', 'ChunkSize', chunksize)
k=0;
%h5write("test.h5","/created_dset_inf2",reshape((1:prod(chunksize))*10**k,chunksize), [ 1+chunksize(1)*k, 1, 1], chunksize)
k = k+1;
k = k+1;
start = [ 1,1,1+chunksize(1)*i];
h5write("test.h5","/created_dset_inf2",cast(reshape((1:prod(chunksize))*10**k,chunksize),'double'), start, chunksize)
k = k+1;
start = [ 1,1,1+chunksize(1)*i];
h5write("test.h5","/created_dset_inf2",cast(reshape((1:prod(chunksize))*10**k,chunksize),'uint32'), start, chunksize)

%%%%%%%%
h5create("test.h5","created_dset_inf23",[ 2 3 4],'Datatype','int8', 'ChunkSize', [2 3 2])

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp("Test h5read hyperslabs...")
check_slice("test.h5", 0);
check_slice("test.h5", 1);
check_slice("test.h5", 2);
check_slice("test.h5", 3);
check_slice("test.h5", 4);
check_slice("test.h5", 1, [2], [2], [2], [1]);
check_slice("test.h5", 2, [1, 2], [2, 1]);
check_slice("test.h5", 3, [1, 2, 1], [2, 1, 2], [2, 1, 1]);
check_slice("test.h5", 3, [2, 1, 1], [2, 2, 2], [2, 3, 1], [1, 2, 1]);
check_slice("test.h5", 4, [2, 1, 1, 2], [2, 2, 2, 1], [2, 3, 1, 3], [1, 2, 1, 1]);

disp("Test h5write hyperslabs...")


disp("Test h5write and h5read...")

function check_dset(location, data)
	 atttype = evalin("caller",["typeinfo(",data,")"]);
	 attclass = evalin("caller",["class(",data,")"]);
	 printf(["write ",num2str(ndims(evalin("caller",data))),"d ",attclass," ",atttype," dataset..."])
	 h5write("test.h5", location,evalin("caller", data));
	 printf("and read it..")
	 readdata = h5read("test.h5", location);
	 if(all(readdata == evalin("caller", data)))
	   disp("ok")
	 elseif(isna(evalin("caller", data)) && isna(readdata))
	   %% this condition is not properly formulated
	   disp("ok")
	 else
	   ## disp("failed, diff:")
	   ## disp(readdata - evalin("caller", data));
	   disp("ref:")
	   disp(evalin("caller", data));
	   disp("data read from file:")
	   disp(readdata)
	 end
end

h5write("test.h5","/rangetest",1:10)
h5write("test.h5","/rangetest2",transpose(1:0.2:2))

s=5
range = cast(1:s**1,'int32');
check_dset('/foo1_range', "range")
matrix = reshape(cast(range,'int16'), length(range),1);
check_dset('/foo1_int', "matrix")
matrix = reshape(cast(1:s**2,'int8'), [s s]);
check_dset('/foo2_int', "matrix")
matrix =reshape(cast(1:s**3,'uint32'), [s s s]);
check_dset('/foo3_int', "matrix")
matrix =reshape(cast(1:s**4,'uint32'), [s s s s]);
check_dset('/foo4_int', "matrix")

range =(1:s**1)*0.1;
check_dset('/foo1_anotherrange', "range")
matrix = reshape(range, length(range),1);
check_dset('/foo1_double', "matrix")
matrix =reshape((1:s**2)*0.1, [s s]);
check_dset('/foo2_double', "matrix")
matrix =reshape((1:s**3)*0.1, [s s s]);
check_dset('/foo3_double', "matrix")
matrix =reshape((1:s**4)*0.1, [s s s s]);
check_dset('/foo4_double', "matrix")

disp("Test h5write and h5read to subgroups...")
matrix = reshape(cast(1:s**2,'int32'), [s s]);
check_dset('/foo/foo2_int', "matrix")
check_dset('/bar1/bar2/foo2_int', "matrix")

disp("Test h5write and h5read for complex data...")
matrix = reshape((1:s**3)*0.1, [s s s]);
matrix = matrix + i*matrix*0.01;
check_dset('/foo_complex', "matrix")

disp("Test h5writeatt and h5readatt...")

function check_att(location, att)
	 atttype = evalin("caller",["typeinfo(",att,")"]);
	 attclass = evalin("caller",["class(",att,")"]);
	 printf(["write ",attclass," ",atttype," attribute..."])
	 h5writeatt("test.h5", location, att,evalin("caller", att));
	 printf("and read it..")
	 readval = h5readatt("test.h5", location, att);
	 if(all(readval == evalin("caller", att)))
	   disp("ok")
	 elseif(isna(evalin("caller", att)) && isna(readval))
	   disp("ok")
	 else
	   disp("failed, not equal")
	   disp(evalin("caller", att));
	   disp(readval)
	 end
end
  
testatt_double = 12.34567;
check_att("/","testatt_double")
% check writing to an existing attribute of the same type
testatt_double *= 10;
check_att("/","testatt_double")

testatt_double_NA = NA;
check_att("/","testatt_double_NA")

testatt2_double = reshape(0.1:0.1:0.5, [5, 1]);
%check_att("/","testatt2_double")

testatt_int = cast(7,'int32')
check_att("/","testatt_int")
% check writing to an existing attribute of a different type
testatt_int = 7.5;
check_att("/","testatt_int")

testatt_string = 'hallo';
check_att("/","testatt_string")
% check overwriting a string attribute
testatt_string = 'buona sera!';
check_att("/","testatt_string")

disp("write to nonexisting file...")
h5write("test2.h5","/foo/bar/test",reshape(1:27,[3 3 3]));


disp("------------ test failures and wrong arguments: ----------------")
try
  % read from a nonexisting file
  data = h5read("nonexistingfile.h5","/foo")
catch
  disp(["error catched: ", lasterror.message])
end

try
  data = h5readatt("test.h5","/foo","too","many","arguments")
catch
  disp(["error catched: ", lasterror.message])
end

try
  data = h5writeatt("test.h5","/nonexisting","testkey","testval")
catch
  disp(["error catched: ", lasterror.message])
end

try
  %create a struct.
  x.a=1;
  x.b="foo";
  h5write("nonexistingfile.h5","/foo",x)
catch
  disp(["error catched: ", lasterror.message])
end


