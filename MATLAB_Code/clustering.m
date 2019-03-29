%************************************************************************************
% Copyright (C) 2016                                                               %
% TETCOS, Bangalore. India                                                         %
%                                                                                  %
% Tetcos owns the intellectual property rights in the Product and its content.     %
% The copying, redistribution, reselling or publication of any or all of the       %
% Product or its content without express prior written consent of Tetcos is        %
% prohibited. Ownership and / or any other right relating to the software and all  %
% intellectual property rights therein shall remain at all times with Tetcos.      %
%                                                                                  %
% Author: 	Dhruvang														       %
%                                                                                  %
% ---------------------------------------------------------------------------------%

function [A,B,C] = clustering(x,scount,num_cls,power,max_energy)
    % changed clustering function. New paramter power: column vector of 
    % remaining power for each device
	% s_count is sensor_count


	% Clustering_Method = 1			KMeans using distance
	%					= 2			Fuzzy C Means using distance
	%				    = 3         KMeans using distance and power
	%					= 4			Fuzzy C Means using distance and power

	Clustering_Method = 1;
	 
%    save dynamic_clustering.mat
	
	%change here for different algorithm
	if(Clustering_Method == 1 || Clustering_Method == 3)
  		[IDX,C]= k_means(x,num_cls);
	else
		[IDX,C]= fuzzy(x,num_cls); 
	end

	
    cl_count=zeros(1,num_cls);
	cl_dist=zeros(1,scount);
		
	if(Clustering_Method > 2)				% only when method involves power
		cl_max_dist = zeros(1,num_cls);		% max distance in each cluster
		cl_max_power = zeros(1,num_cls);	% max device power left in each cluster
	end
	
% Calculation of Distance from each sensor to the centroid of its cluster and size of each cluster
	
	for index1=1:1:num_cls
		for index2=1:1:scount
			if IDX(index2)==index1
				cl_count(index1)=cl_count(index1)+1;
				cl_dist(index2)= pdist([C(index1),C(num_cls+index1);x(index2,1),x(index2,2)],'euclidean'); % hard coded to be modified
				
				if(Clustering_Method > 2)			% only when method involves power
					if cl_max_dist(index1) < cl_dist(index2)
					   cl_max_dist(index1) = cl_dist(index2);
					end

					if cl_max_power(index1) < power(index2)
					   cl_max_power(index1) = power(index2);
					end
				end
			end 
		end
	end


	cl_index= zeros(1,num_cls);
	c_head= zeros(1,num_cls);


% Cluster Head election

	for index1=1:1:num_cls
		if(Clustering_Method > 2)	
			curr_cl_max_p = cl_max_power(index1);
			curr_cl_max_d = cl_max_dist(index1);
		end

		prev_dist_p = 100000;
		for index2=1:1:scount    
		 if IDX(index2)==index1 
			 cl_index(index1)=cl_index(index1)+1;
			 curr_var = cl_dist(index2);
			 
			 if(Clustering_Method > 2)		% only when method involves power
				curr_var = (curr_cl_max_p * cl_dist(index2)/(curr_cl_max_d + 0.0001)) - 10*power(index2);               
			 end
			 
			 if(min(prev_dist_p,curr_var)== curr_var)
				c_head(index1)=  index2;
				prev_dist_p= curr_var;
			 end

		 end

		end  
	end

% Graph plotting starts here

% 	clf
% 	color=char('r','b','m','g','y','c','k');
% 
% 	for index=1:1:num_cls
% 	exp=strcat('plot(x(IDX==',num2str(index),',1),x(IDX==',num2str(index),',2),''',color(rem(index,7)),'.'',''MarkerSize'',12)');
% 	eval(exp);
% 	exp='hold on';
% 	eval(exp)
% 	end
% 
% 	plot(C(:,1),C(:,2),'ko',...
% 		 'MarkerSize',12,'LineWidth',2)
% 
% 	exp='legend(';
% 
% 	for index=1:1:num_cls
% 	exp=strcat(exp,'''Cluster ',num2str(index),''',');
% 	end
% 	exp=strcat(exp,'''Centroids'',''Location'',''NW'')');
% 	eval(exp);

%Graph plotting ends here   



% 3D graph plotting starts here
tri = delaunay(x(:,1),x(:,2));
consumed = max_energy-power;
h = trisurf(tri,x(:,1),x(:,2),consumed);
%axis vis3d
x_max = max(x(:,1));
y_max = max(x(:,2));
p_max = max(consumed)+200;
axis([0 x_max 0 y_max 0 p_max]); 
xlabel('Sensor X position') 
ylabel('Sensor Y position') 
zlabel('Energy Consumed (mJ)')
lighting phong
shading interp
colorbar EastOutside


% 3D graph plotting ends here


   
	A=c_head;    % contains the cluster head id's of each cluster
	B=IDX;	     % contains the cluster id's of each sensor
	C=cl_count;  % contains the size of each cluster

end



function [IDX,C] = k_means(x,num_cls)
	[IDX,C] = kmeans(x,num_cls)
end


function [IDX,C] = fuzzy(x,num_cls)
	[C,U]= fcm(x,num_cls);      % C is centers of each cluster
	IDX = zeros(size(x,1),1);
    
	rng(1);
	for i=1:1:size(x,1)
		temp_var = rand;
		curr_prob = 0;
        for j=1:1:num_cls
           curr_prob = curr_prob + U(j,i);
           if temp_var <= curr_prob
               IDX(i,1)= j;
               break;
           end
	    end
    end
end


function [IDX,C] = gauss_mix_model(x,num_cls)
	rng(1);
	obj = gmdistribution.fit(x,num_cls,'Regularize',0.01);
	IDX = cluster(obj,X);
	
	post_prob = posterior(obj,X);
	d = size(x,2);

	C=zeros(num_cls,d);
	for i=1:1:num_cls
		[maxi,index] = max(post_prob(:,i));
		for j=1:1:d
			C(i,j) = x(index,j);
		end
	end

end


