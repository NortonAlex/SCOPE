function atmo = load_atmo(atmfile, SCOPEspec, dtselect)
    % default error is not clear enough
    assert(exist(atmfile, 'file') == 2, 'Atmospheric file `%s` does not exist', atmfile)
    [~, ~, ext] = fileparts(atmfile);
    if strcmp(ext, '.atm')
        atmo.M  = aggreg(atmfile, SCOPEspec);
    elseif strcmp(ext, '.scale')  
        % Option to prescribe incoming spectra in terms of the spectral
        % shape and diffuse fraction, but scale the total flux with 
        % prescribed shortwave and longwave broadband fluxes (Rin, Rli).
        % read in the Esun file
        Esun_spectra_file = atmfile;
        % we assume the filenames are equivalent except for Esun and Esky
        Esky_spectra_file = strrep(atmfile,'Esun','Esky');
        fprintf(1,'warning: using prescribed top-of-canopy spectra, not MODTRAN inputs \n');
        
        %for timeseries simulation, select nearest time index
        %read in the DOY variable from the spectra files
        s=importdata(atmfile);
        tEsun=s(2:end,1);
        tEsun=timestamp2datetime(tEsun);
        s=importdata(Esky_spectra_file);
        tEsky=s(2:end,1);
        tEsky=timestamp2datetime(tEsky);
        if any(~(datenum(tEsun)==datenum(tEsky)))
            fprintf(1,'%s %s %s\n', 'warning: time column of prescribed spectra files do not match"',char(atmo.Esun_spectra_file),'" and "',char(atmo.Esky_spectra_file),'"');
        end
        %find nearest time index in prescribed spectra file to current timestep
        [~, dtnearestIdx] = min(abs(dtselect - tEsky));
        
        % read spectra (nearest timestep) and aggregate over SCOPE bands
        atmo.Esun_ = aggreg_hyperspectral(Esun_spectra_file,SCOPEspec,dtnearestIdx);
        atmo.Esky_ = aggreg_hyperspectral(Esky_spectra_file,SCOPEspec,dtnearestIdx);
        % check to ensure there are no nans
        Esun_quality_is_ok   = ~isnan(atmo.Esun_);
        Esky_quality_is_ok   = ~isnan(atmo.Esky_);
        if any(~Esun_quality_is_ok)
            fprintf(1,'error: NaNs in prescribed top-of-canopy Esun spectra, terminating \n');
            return
        elseif any(~Esky_quality_is_ok)
            fprintf(1,'error: NaNs in prescribed top-of-canopy Esky spectra, terminating \n');
            return
        end
        % add this flag for use in RTMo.m
        atmo.scale = 1;
    else
        raddata = load(atmfile);
        atmo.Esun_ = raddata(:,1);
        atmo.Esky_ = raddata(:,2);
    end
end